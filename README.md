# Superpowers for GitHub Copilot

A maintained GitHub Copilot adaptation of [obra/superpowers](https://github.com/obra/superpowers), Jesse Vincent's structured software-development workflow system.

This fork packages the upstream skill model for GitHub Copilot in VS Code. It adds project-scoped installers, reusable prompt files, and an explicit mapping from the tool names used by the upstream skills to Copilot agent-mode tools.

## What It Provides

- 14 composable skills for discovery, planning, implementation, debugging, review, and branch completion.
- PowerShell and Bash installers that preserve existing project guidance.
- Four prompt files for common entry points: brainstorm, plan, execute, and debug.
- A Copilot-specific tool mapping for skills originally written for Claude Code.
- A repeatable uninstall path that removes only the managed Superpowers block and prompt files.

The installer changes the project in which it is run. It does not install VS Code, enable GitHub Copilot, modify global Copilot settings, or execute a skill automatically.

## Quick Start

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

The installer creates or updates `.github/copilot-instructions.md` and copies four prompt files into `.github/prompts/`. Re-running it updates the managed block without duplicating it.

Start a new Copilot chat in agent mode and try:

- `/brainstorm` for design discovery.
- `/write-plan` for an implementation plan.
- `/execute-plan` to work through a written plan.
- `/debug` for systematic diagnosis.

See the [installation guide](.copilot/INSTALL.md) for manual setup, updating, verification, and uninstall instructions.

## Workflow

1. `brainstorming` turns an initial request into a reviewed design.
2. `using-git-worktrees` prepares an isolated branch and verifies the starting state.
3. `writing-plans` decomposes the design into testable implementation tasks.
4. `executing-plans` or `subagent-driven-development` carries out the plan.
5. `test-driven-development` keeps implementation in a red-green-refactor loop.
6. `requesting-code-review` and `receiving-code-review` structure review and response.
7. `verification-before-completion` requires fresh evidence before completion claims.
8. `finishing-a-development-branch` closes the branch with an explicit integration decision.

These are instruction assets, not runtime enforcement. Their effectiveness depends on the Copilot model, available tools, workspace permissions, and the quality of the surrounding project context.

## Skill Library

| Area | Skills |
| --- | --- |
| Design and planning | `brainstorming`, `writing-plans` |
| Implementation | `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents` |
| Quality | `test-driven-development`, `systematic-debugging`, `verification-before-completion` |
| Review and delivery | `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `finishing-a-development-branch` |
| System guidance | `using-superpowers`, `writing-skills` |

## Copilot Tool Mapping

| Skill reference | Copilot equivalent |
| --- | --- |
| `Task` | `runSubagent` |
| `TodoWrite` | `manage_todo_list` |
| `Skill` | `read_file` on the relevant `SKILL.md` |
| `Read` | `read_file` |
| `Write` | `create_file` |
| `Edit` | `replace_string_in_file` or `multi_replace_string_in_file` |
| `Bash` | `run_in_terminal` |

The full compatibility notes are in [Copilot tools](skills/using-superpowers/references/copilot-tools.md) and the [Copilot usage guide](docs/README.copilot.md).

## Maintenance

Run the local quality suite before proposing a change:

```powershell
pwsh -NoProfile -File tests/test_repository.ps1
```

The suite checks documentation links and code fences, installer syntax, PowerShell install/update/uninstall behavior, prompt-file delivery, and preservation of upstream attribution. It does not depend on GitHub Actions.

Contribution expectations are documented in [CONTRIBUTING.md](CONTRIBUTING.md). Security reports should follow [SECURITY.md](SECURITY.md).

## Upstream and License

This repository is a maintained fork of [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent. The upstream authorship and MIT license are preserved. Copilot-specific changes in this fork do not imply authorship of the upstream workflow or skills.

See [LICENSE](LICENSE) for the license text.
