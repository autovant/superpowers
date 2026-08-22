# Install Superpowers for GitHub Copilot

## Prerequisites

- VS Code with GitHub Copilot Chat.
- Copilot agent mode for tool-using workflows.
- Git.
- PowerShell 7 on Windows, or Bash on macOS/Linux.

## Recommended Installation

Clone this repository once, then run its installer from each project that should use the skills.

### Windows PowerShell

```powershell
git clone https://github.com/autovant/superpowers.git "$env:USERPROFILE\.copilot\superpowers"
Set-Location path\to\your-project
& "$env:USERPROFILE\.copilot\superpowers\install.ps1"
```

### macOS or Linux

```bash
git clone https://github.com/autovant/superpowers.git ~/.copilot/superpowers
cd path/to/your-project
~/.copilot/superpowers/install.sh
```

The installer performs two project-scoped changes:

1. It creates or updates a marked Superpowers block in `.github/copilot-instructions.md`.
2. It copies four `.prompt.md` files into `.github/prompts/`.

Existing content outside the marked block is preserved. Re-running the installer replaces the managed block instead of duplicating it.

## Manual Installation

If scripts are not appropriate for the project:

1. Create `.github/copilot-instructions.md` if it does not exist.
2. Add guidance that tells Copilot to read `~/.copilot/superpowers/skills/using-superpowers/SKILL.md` before work and lists the relevant skill paths.
3. Copy the prompt files into the project.

PowerShell:

```powershell
New-Item -ItemType Directory -Force -Path '.github\prompts'
Copy-Item "$env:USERPROFILE\.copilot\superpowers\.copilot\prompts\*.prompt.md" '.github\prompts\'
```

Bash:

```bash
mkdir -p .github/prompts
cp ~/.copilot/superpowers/.copilot/prompts/*.prompt.md .github/prompts/
```

Use [Copilot tools](../skills/using-superpowers/references/copilot-tools.md) as the compatibility reference when adapting skill instructions.

## Verify

Confirm these files exist in the target project:

```text
.github/copilot-instructions.md
.github/prompts/brainstorm.prompt.md
.github/prompts/debug.prompt.md
.github/prompts/execute-plan.prompt.md
.github/prompts/write-plan.prompt.md
```

Start a new Copilot chat in agent mode and ask it to plan a small feature. Confirm that it reads the relevant `SKILL.md` before proposing implementation.

## Update

Pull the latest fork, then re-run the installer in each target project:

```bash
cd ~/.copilot/superpowers
git pull --ff-only
```

Re-running the installer refreshes the managed instruction block and prompt files.

## Uninstall From a Project

Windows PowerShell:

```powershell
& "$env:USERPROFILE\.copilot\superpowers\install.ps1" -Uninstall
```

macOS or Linux:

```bash
~/.copilot/superpowers/install.sh --uninstall
```

Uninstall removes the managed Superpowers block and the four copied prompt files. It preserves other project instructions and files.

Deleting the cloned repository is a separate, optional cleanup step and should be done only after no projects depend on its skill paths.
