[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$passed = 0
$failed = 0

function Write-TestResult {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [bool]$Succeeded,

        [string]$Detail = ''
    )

    if ($Succeeded) {
        $script:passed++
        Write-Host "PASS: $Name"
        return
    }

    $script:failed++
    Write-Host "FAIL: $Name"
    if ($Detail) {
        Write-Host "  $Detail"
    }
}

$requiredFiles = @(
    'README.md',
    'LICENSE',
    'CONTRIBUTING.md',
    'SECURITY.md',
    '.github/pull_request_template.md',
    '.copilot/INSTALL.md',
    'docs/README.copilot.md',
    'install.ps1',
    'install.sh'
)
$missingFiles = @($requiredFiles | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $repositoryRoot $_) -PathType Leaf)
})
Write-TestResult -Name 'includes public maintainer and security documents' -Succeeded ($missingFiles.Count -eq 0) -Detail ($missingFiles -join ', ')

$markdownFiles = @(
    'README.md',
    '.copilot/INSTALL.md',
    'docs/README.copilot.md',
    'CONTRIBUTING.md',
    'SECURITY.md'
) | Where-Object { Test-Path -LiteralPath (Join-Path $repositoryRoot $_) }

$unbalancedFences = @()
$brokenLinks = @()
foreach ($relativePath in $markdownFiles) {
    $path = Join-Path $repositoryRoot $relativePath
    $content = Get-Content -LiteralPath $path -Raw
    $fenceCount = ([regex]::Matches($content, '(?m)^```')).Count
    if (($fenceCount % 2) -ne 0) {
        $unbalancedFences += $relativePath
    }

    foreach ($match in [regex]::Matches($content, '!?(?:\[[^\]]*\])\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim()
        if ($target -match '^(?:https?://|mailto:|#)') {
            continue
        }

        $targetPath = ($target -split '#', 2)[0]
        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            continue
        }
        $resolved = Join-Path (Split-Path -Parent $path) $targetPath
        if (-not (Test-Path -LiteralPath $resolved)) {
            $brokenLinks += "$relativePath -> $target"
        }
    }
}
Write-TestResult -Name 'keeps Markdown code fences balanced' -Succeeded ($unbalancedFences.Count -eq 0) -Detail ($unbalancedFences -join ', ')
Write-TestResult -Name 'keeps local Markdown links resolvable' -Succeeded ($brokenLinks.Count -eq 0) -Detail ($brokenLinks -join ', ')

$readme = Get-Content -LiteralPath (Join-Path $repositoryRoot 'README.md') -Raw
Write-TestResult -Name 'preserves explicit upstream attribution' -Succeeded ($readme -match 'https://github\.com/obra/superpowers' -and $readme -match 'Jesse Vincent')

$allMarkdown = $markdownFiles | ForEach-Object { Get-Content -LiteralPath (Join-Path $repositoryRoot $_) -Raw }
$qualityFindings = @($allMarkdown | Select-String -Pattern '\b(?:TODO|TBD|FIXME)\b|UPDATE THIS PATH|<<<<<<<|=======|>>>>>>>' -AllMatches -CaseSensitive)
Write-TestResult -Name 'contains no placeholders or merge artifacts' -Succeeded ($qualityFindings.Count -eq 0) -Detail ($qualityFindings -join ', ')

$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $repositoryRoot 'install.ps1'),
    [ref]$null,
    [ref]$parseErrors
)
Write-TestResult -Name 'PowerShell installer parses cleanly' -Succeeded ($parseErrors.Count -eq 0) -Detail ($parseErrors -join '; ')

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
$gitBash = if ($gitCommand) {
    $gitRoot = Split-Path -Parent (Split-Path -Parent $gitCommand.Source)
    Join-Path $gitRoot 'bin\bash.exe'
} else {
    $null
}
if ($gitBash -and (Test-Path -LiteralPath $gitBash)) {
    & $gitBash -n (Join-Path $repositoryRoot 'install.sh')
    Write-TestResult -Name 'Bash installer parses cleanly' -Succeeded ($LASTEXITCODE -eq 0)
} else {
    Write-Host 'SKIP: Bash installer syntax check (Git Bash unavailable)'
}

$tempParent = [System.IO.Path]::GetTempPath()
$tempRoot = Join-Path $tempParent ("superpowers-repository-tests-" + [guid]::NewGuid().ToString('N'))
try {
    $null = New-Item -ItemType Directory -Path $tempRoot -Force
    $instructionsPath = Join-Path $tempRoot '.github\copilot-instructions.md'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $instructionsPath) -Force
    Set-Content -LiteralPath $instructionsPath -Value 'Existing project guidance.' -NoNewline

    Push-Location $tempRoot
    try {
        & (Join-Path $repositoryRoot 'install.ps1') *> $null
        & (Join-Path $repositoryRoot 'install.ps1') *> $null
        $installedContent = Get-Content -LiteralPath $instructionsPath -Raw
        $startMarkerCount = ([regex]::Matches($installedContent, '<!-- SUPERPOWERS:START -->')).Count
        $promptCount = @(Get-ChildItem -LiteralPath (Join-Path $tempRoot '.github\prompts') -Filter '*.prompt.md').Count
        Write-TestResult -Name 'PowerShell installer is idempotent and copies four prompts' -Succeeded ($startMarkerCount -eq 1 -and $promptCount -eq 4) -Detail "markers=$startMarkerCount prompts=$promptCount"

        & (Join-Path $repositoryRoot 'install.ps1') -Uninstall *> $null
        $uninstalledContent = Get-Content -LiteralPath $instructionsPath -Raw
        $remainingPrompts = if (Test-Path -LiteralPath (Join-Path $tempRoot '.github\prompts')) {
            @(Get-ChildItem -LiteralPath (Join-Path $tempRoot '.github\prompts') -Filter '*.prompt.md').Count
        } else {
            0
        }
        Write-TestResult -Name 'PowerShell uninstaller preserves existing guidance' -Succeeded ($uninstalledContent -eq 'Existing project guidance.' -and $remainingPrompts -eq 0) -Detail "remaining_prompts=$remainingPrompts content='$uninstalledContent'"
    }
    finally {
        Pop-Location
    }
}
finally {
    $resolvedParent = [System.IO.Path]::GetFullPath($tempParent)
    $resolvedRoot = [System.IO.Path]::GetFullPath($tempRoot)
    if ($resolvedRoot.StartsWith($resolvedParent, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolvedRoot)) {
        Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
    }
}

Write-Host "RESULT: $passed passed, $failed failed"
if ($failed -gt 0) {
    exit 1
}

exit 0
