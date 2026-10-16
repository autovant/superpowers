# Superpowers for GitHub Copilot

[![Tests](https://github.com/autovant/superpowers/actions/workflows/tests.yml/badge.svg)](https://github.com/autovant/superpowers/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Adapted from obra/superpowers](https://img.shields.io/badge/adapted%20from-obra%2Fsuperpowers-blue)](https://github.com/obra/superpowers)

Jesse Vincent's Superpowers skill library, installed into any project as GitHub Copilot custom instructions, so agent mode brainstorms, plans, tests first, debugs, verifies and asks for review before it calls work done.

> **Credit.** The workflow and the skills are the work of [Jesse Vincent](https://github.com/obra) and the contributors to [obra/superpowers](https://github.com/obra/superpowers), released under the MIT license. This repository adapts that work for GitHub Copilot. It does not claim authorship of the upstream workflow or skills.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/workflow-dark.svg">
  <img alt="Workflow: brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion, requesting-code-review, with a loop from debugging back to TDD" src="docs/images/workflow-light.svg">
</picture>

## What it does

- Ships the 14 upstream skills as plain `SKILL.md` files that Copilot agent mode reads with `read_file`.
- Installs per project: one marked block in `.github/copilot-instructions.md` plus four prompt files (`/brainstorm`, `/write-plan`, `/execute-plan`, `/debug`).
- Preserves the guidance a project already has. Re-running the installer updates the block in place, and `-Uninstall` removes only what it added.
- Maps the Claude Code tool names the skills use (`Task`, `TodoWrite`, `Bash`, ...) to Copilot agent-mode tools.
- Runs a PowerShell test suite in CI on every push and pull request.

It does not install VS Code, enable Copilot, change global Copilot settings, or run a skill by itself.

## Install

Clone once, then run the installer from the root of each project that should use the skills.

**Windows (PowerShell 7)**

```powershell
git clone https://github.com/autovant/superpowers.git "$env:USERPROFILE\.copilot\superpowers"
Set-Location path\to\your-project
& "$env:USERPROFILE\.copilot\superpowers\install.ps1"
```

**macOS or Linux (Bash)**

```bash
git clone https://github.com/autovant/superpowers.git ~/.copilot/superpowers
cd path/to/your-project
~/.copilot/superpowers/install.sh
```

A real run in a sample project that already had its own instructions: install, re-install, then uninstall back to the original file.

![install.ps1 output in a sample project](docs/images/install-ps1.png)

Then start a new Copilot chat in agent mode and try `/brainstorm`, `/write-plan`, `/execute-plan` or `/debug`. GitHub Copilot CLI picks up the same file as a repository instruction source:

![copilot instruction list showing .github/copilot-instructions.md](docs/images/copilot-instructions-discovered.png)

To remove it from a project, run `install.ps1 -Uninstall` or `install.sh --uninstall`. The [installation guide](.copilot/INSTALL.md) covers manual setup, updating and verification, and the [Copilot usage guide](docs/README.copilot.md) covers troubleshooting.

## Skill catalogue

| Stage | Skill | Use it when |
| --- | --- | --- |
| Entry point | `using-superpowers` | Starting any task. It tells the agent how to find and load the other skills. |
| Design | `brainstorming` | Before building anything. It turns a rough request into a reviewed design. |
| Isolation | `using-git-worktrees` | Starting feature work that should not touch the current workspace. |
| Planning | `writing-plans` | You have a spec and need small, testable implementation tasks. |
| Execution | `executing-plans` | Working through a written plan with review checkpoints. |
| Execution | `subagent-driven-development` | Running a plan's independent tasks through subagents, with review between tasks. |
| Execution | `dispatching-parallel-agents` | Two or more tasks have no shared state and can run in parallel. |
| Implementation | `test-driven-development` | Writing any feature or bug fix. Test first, watch it fail, then make it pass. |
| Diagnosis | `systematic-debugging` | Any bug, test failure or unexpected behaviour, before proposing a fix. |
| Evidence | `verification-before-completion` | About to say something is done, fixed or passing. Run the check first. |
| Review | `requesting-code-review` | A task or feature is complete and needs review before merge. |
| Review | `receiving-code-review` | Acting on review feedback. Verify it before agreeing with it. |
| Delivery | `finishing-a-development-branch` | Tests pass and you need to choose merge, PR or clean-up. |
| Meta | `writing-skills` | Creating or editing a skill and testing that it works. |

Tool names in the skill text are upstream's Claude Code names. Copilot uses these equivalents:

| Skill reference | Copilot equivalent |
| --- | --- |
| `Task` | `runSubagent` |
| `TodoWrite` | `manage_todo_list` |
| `Skill` | `read_file` on the relevant `SKILL.md` |
| `Read` | `read_file` |
| `Write` | `create_file` |
| `Edit` | `replace_string_in_file` or `multi_replace_string_in_file` |
| `Bash` | `run_in_terminal` |

Details and caveats are in [Copilot tools](skills/using-superpowers/references/copilot-tools.md).

## What's different from upstream

This repository started from upstream release v5.0.0 (commit `33e55e6`, March 2026).

| | Change |
| --- | --- |
| Added | `install.ps1` and `install.sh`: project-scoped installers that manage a marked block and can uninstall cleanly. |
| Added | Four `.prompt.md` files for Copilot slash-command entry points. |
| Added | [`copilot-tools.md`](skills/using-superpowers/references/copilot-tools.md), the tool-name mapping, and a Copilot usage guide. |
| Added | A repository test suite and a CI workflow that runs it on Windows. |
| Changed | `using-superpowers/SKILL.md` loads skills with `read_file` and names Copilot instruction files instead of `CLAUDE.md`. |
| Unchanged | The other 13 skills' text is the same as upstream v5.0.0. |
| Removed | Plugin packaging for Claude Code, Cursor, Codex and OpenCode, the session-start hooks, upstream's slash commands and agent definition, `lib/` (including the brainstorm server), upstream's test harnesses, release notes and design plans. |

## Tests

```powershell
pwsh -NoProfile -File tests/test_repository.ps1
```

The suite checks required files, Markdown links and code fences, upstream attribution, both installers' syntax, and install, re-install and uninstall behaviour in a temporary project. CI runs it on `windows-latest`.

![Repository test suite: 9 passed, 0 failed](docs/images/test-suite.png)

## Limitations

- The skills are instructions, not enforcement. Whether Copilot follows them depends on the model, the tools agent mode exposes, workspace permissions and project context.
- Some skill text still uses Claude Code terms (for example "Task tool" or "Skill tool"). The installed block and the mapping above translate them; the skills themselves are kept close to upstream on purpose.
- The brainstorming skill's optional visual companion (`skills/brainstorming/visual-companion.md`) refers to a browser server under `lib/` that this adaptation does not ship, so that option does not work here.
- The installed block points at the clone's skill paths. Moving or deleting the clone breaks them until you re-run the installer.
- Upstream has released newer versions since v5.0.0. Changes from them are not merged here yet.

## Contributing, security and license

See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md). Changes to an upstream skill's core behaviour are better proposed to [obra/superpowers](https://github.com/obra/superpowers) first.

MIT. The [LICENSE](LICENSE) file is upstream's, `Copyright (c) 2025 Jesse Vincent`, kept unchanged. Copilot-specific changes in this repository are released under the same license.
