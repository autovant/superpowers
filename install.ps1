<#
.SYNOPSIS
    Installs Superpowers skills into the current project for GitHub Copilot.

.DESCRIPTION
    Adds superpowers copilot-instructions block and prompt files to the current
    project. Run this from any project root to enable superpowers in that project.

.PARAMETER Uninstall
    Remove superpowers from the current project.

.EXAMPLE
    & "$env:USERPROFILE\.copilot\superpowers\install.ps1"

.EXAMPLE
    & "$env:USERPROFILE\.copilot\superpowers\install.ps1" -Uninstall
#>
[CmdletBinding()]
param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

# Resolve superpowers root (where this script lives)
$SuperpowersRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Resolve skills path (use relative path from project root if superpowers is in ~/.copilot)
$HomeCopilotPath = Join-Path $env:USERPROFILE '.copilot\superpowers'
if ($SuperpowersRoot -eq $HomeCopilotPath) {
    $SkillsPrefix = '~/.copilot/superpowers/skills'
} else {
    $SkillsPrefix = $SuperpowersRoot.Replace('\', '/') + '/skills'
}

$ProjectRoot = Get-Location
$GithubDir = Join-Path $ProjectRoot '.github'
$PromptsDir = Join-Path $GithubDir 'prompts'
$InstructionsFile = Join-Path $GithubDir 'copilot-instructions.md'
# Records every prompt file this installer wrote ("<sha256>  <name>"), so install
# and uninstall only touch files Superpowers owns. Same format as install.sh.
$ManifestFile = Join-Path $PromptsDir '.superpowers-manifest'

$StartMarker = '<!-- SUPERPOWERS:START -->'
$EndMarker = '<!-- SUPERPOWERS:END -->'

# Build the instructions block
$InstructionsBlock = @"
$StartMarker
## Superpowers

You have superpowers — a structured software development workflow system.

**Before starting any task**, check if a skill applies. If there is even a 1% chance a skill is relevant, read it.

### Loading Skills

To load a skill, use ``read_file`` on the SKILL.md file path below. Read the skill content and follow the workflow it describes.

#### Core Skill (read this first on any new task)

- **using-superpowers**: $SkillsPrefix/using-superpowers/SKILL.md

#### Available Skills

- **brainstorming**: $SkillsPrefix/brainstorming/SKILL.md
- **writing-plans**: $SkillsPrefix/writing-plans/SKILL.md
- **executing-plans**: $SkillsPrefix/executing-plans/SKILL.md
- **subagent-driven-development**: $SkillsPrefix/subagent-driven-development/SKILL.md
- **test-driven-development**: $SkillsPrefix/test-driven-development/SKILL.md
- **systematic-debugging**: $SkillsPrefix/systematic-debugging/SKILL.md
- **verification-before-completion**: $SkillsPrefix/verification-before-completion/SKILL.md
- **requesting-code-review**: $SkillsPrefix/requesting-code-review/SKILL.md
- **receiving-code-review**: $SkillsPrefix/receiving-code-review/SKILL.md
- **using-git-worktrees**: $SkillsPrefix/using-git-worktrees/SKILL.md
- **finishing-a-development-branch**: $SkillsPrefix/finishing-a-development-branch/SKILL.md
- **dispatching-parallel-agents**: $SkillsPrefix/dispatching-parallel-agents/SKILL.md
- **writing-skills**: $SkillsPrefix/writing-skills/SKILL.md

### Tool Mapping

Skills reference Claude Code tool names. Use these Copilot equivalents:

| Claude Code tool | Copilot equivalent |
|-----------------|-------------------|
| ``Task`` (dispatch subagent) | ``runSubagent`` |
| ``TodoWrite`` (task tracking) | ``manage_todo_list`` |
| ``Skill`` (invoke a skill) | ``read_file`` on the SKILL.md path |
| ``Read`` (read files) | ``read_file`` |
| ``Write`` (create files) | ``create_file`` |
| ``Edit`` (edit files) | ``replace_string_in_file`` or ``multi_replace_string_in_file`` |
| ``Bash`` (run commands) | ``run_in_terminal`` |

Full mapping: $SkillsPrefix/using-superpowers/references/copilot-tools.md
$EndMarker
"@

function Get-FileSha256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-Manifest {
    $map = @{}
    if (Test-Path -LiteralPath $ManifestFile) {
        foreach ($line in Get-Content -LiteralPath $ManifestFile) {
            if ($line -match '^([0-9a-f]{64})\s+(.+)$') { $map[$Matches[2]] = $Matches[1] }
        }
    }
    return $map
}

function Write-Manifest([hashtable]$Map) {
    $lines = @($Map.Keys | Sort-Object | ForEach-Object { '{0}  {1}' -f $Map[$_], $_ })
    if ($lines.Count -eq 0) { return }
    Set-Content -LiteralPath $ManifestFile -Value (($lines -join "`n") + "`n") -NoNewline
}

function Install-Superpowers {
    Write-Host "Installing Superpowers into: $ProjectRoot" -ForegroundColor Cyan

    # Create .github directory
    if (-not (Test-Path $GithubDir)) {
        New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
        Write-Host "  Created .github/" -ForegroundColor Green
    }

    # Update or create copilot-instructions.md
    if (Test-Path $InstructionsFile) {
        $content = Get-Content $InstructionsFile -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { $content = '' }

        if ($content -match [regex]::Escape($StartMarker)) {
            # Replace existing superpowers block
            $pattern = [regex]::Escape($StartMarker) + '[\s\S]*?' + [regex]::Escape($EndMarker)
            $content = [regex]::Replace($content, $pattern, $InstructionsBlock)
            Set-Content -Path $InstructionsFile -Value $content -NoNewline
            Write-Host "  Updated superpowers block in copilot-instructions.md" -ForegroundColor Green
        } else {
            # Append to existing file
            Add-Content -Path $InstructionsFile -Value "`n`n$InstructionsBlock"
            Write-Host "  Appended superpowers block to copilot-instructions.md" -ForegroundColor Green
        }
    } else {
        Set-Content -Path $InstructionsFile -Value $InstructionsBlock
        Write-Host "  Created copilot-instructions.md" -ForegroundColor Green
    }

    # Copy prompt files
    $SourcePrompts = Join-Path $SuperpowersRoot '.copilot\prompts'
    if (Test-Path $SourcePrompts) {
        if (-not (Test-Path $PromptsDir)) {
            New-Item -ItemType Directory -Path $PromptsDir -Force | Out-Null
        }
        $manifest = Read-Manifest
        $installed = 0
        $kept = 0
        foreach ($src in Get-ChildItem -LiteralPath $SourcePrompts -Filter '*.prompt.md') {
            $name = $src.Name
            $dest = Join-Path $PromptsDir $name
            $srcHash = Get-FileSha256 $src.FullName
            if (-not (Test-Path -LiteralPath $dest)) {
                Copy-Item -LiteralPath $src.FullName -Destination $dest
                $manifest[$name] = $srcHash
                $installed++
                continue
            }
            $destHash = Get-FileSha256 $dest
            if ($destHash -eq $srcHash) {
                # Identical to ours: adopt it (covers installs made before the manifest existed).
                $manifest[$name] = $srcHash
                $installed++
            } elseif ($manifest.ContainsKey($name) -and $manifest[$name] -eq $destHash) {
                # Ours and unmodified: refresh to the current version.
                Copy-Item -LiteralPath $src.FullName -Destination $dest -Force
                $manifest[$name] = $srcHash
                $installed++
            } else {
                Write-Host "  Kept existing .github/prompts/$name (not installed by Superpowers, or edited since)" -ForegroundColor DarkGray
                $kept++
            }
        }
        Write-Manifest $manifest
        Write-Host "  Installed $installed prompt files to .github/prompts/ (kept $kept existing)" -ForegroundColor Green
    }

    Write-Host "`nSuperpowers installed! Start a new Copilot chat to use them." -ForegroundColor Cyan
    Write-Host "  Try: /brainstorm, /write-plan, /execute-plan, /debug" -ForegroundColor DarkGray
}

function Uninstall-Superpowers {
    Write-Host "Removing Superpowers from: $ProjectRoot" -ForegroundColor Cyan

    # Remove superpowers block from copilot-instructions.md
    if (Test-Path $InstructionsFile) {
        $content = Get-Content $InstructionsFile -Raw
        if ($content -match [regex]::Escape($StartMarker)) {
            $pattern = '\r?\n?\r?\n?' + [regex]::Escape($StartMarker) + '[\s\S]*?' + [regex]::Escape($EndMarker)
            $content = [regex]::Replace($content, $pattern, '')
            $content = $content.Trim()
            if ($content.Length -eq 0) {
                Remove-Item $InstructionsFile
                Write-Host "  Removed copilot-instructions.md (was empty)" -ForegroundColor Yellow
            } else {
                Set-Content -Path $InstructionsFile -Value $content -NoNewline
                Write-Host "  Removed superpowers block from copilot-instructions.md" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  No superpowers block found in copilot-instructions.md" -ForegroundColor DarkGray
        }
    }

    # Remove only the prompt files this installer owns and the user has not edited.
    $manifest = Read-Manifest
    $SourcePrompts = Join-Path $SuperpowersRoot '.copilot\prompts'
    $promptFiles = @('brainstorm.prompt.md', 'write-plan.prompt.md', 'execute-plan.prompt.md', 'debug.prompt.md')
    foreach ($f in $promptFiles) {
        $path = Join-Path $PromptsDir $f
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $owned = $manifest[$f]
        # No manifest entry (pre-manifest install): owned only if identical to our copy.
        if (-not $owned -and (Test-Path -LiteralPath (Join-Path $SourcePrompts $f))) {
            $owned = Get-FileSha256 (Join-Path $SourcePrompts $f)
        }
        if ($owned -and $owned -eq (Get-FileSha256 $path)) {
            Remove-Item -LiteralPath $path
            Write-Host "  Removed .github/prompts/$f" -ForegroundColor Yellow
        } else {
            Write-Host "  Kept .github/prompts/$f (not installed by Superpowers, or edited since)" -ForegroundColor DarkGray
        }
    }
    if (Test-Path -LiteralPath $ManifestFile) { Remove-Item -LiteralPath $ManifestFile }

    # Clean up empty directories
    if ((Test-Path $PromptsDir) -and (Get-ChildItem $PromptsDir | Measure-Object).Count -eq 0) {
        Remove-Item $PromptsDir
    }

    Write-Host "`nSuperpowers removed." -ForegroundColor Cyan
}

# Main
if ($Uninstall) {
    Uninstall-Superpowers
} else {
    Install-Superpowers
}
