

# Superpowers for GitHub Copilot

A complete software development workflow system for GitHub Copilot in VS Code, built on composable "skills" that enforce best practices for brainstorming, planning, TDD, debugging, and code review.

## How it works

When you fire up Copilot, it doesn't just jump into writing code. Instead, it steps back and asks you what you're really trying to do.

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest.

After you've signed off on the design, Copilot puts together an implementation plan that's clear enough for an enthusiastic junior engineer to follow. It emphasizes true red/green TDD, YAGNI, and DRY.

Then it launches a *subagent-driven-development* process, dispatching agents to work through each engineering task, inspecting and reviewing their work, and continuing forward.

Skills trigger automatically — your coding agent just has Superpowers.

## Quick Install

### Option 1: Installer Script (recommended)

First, clone the repo once:
```bash
git clone https://github.com/autovant/superpowers.git ~/.copilot/superpowers
```

Then run in any project to add superpowers:

**PowerShell (Windows):**
```powershell
& "$env:USERPROFILE\.copilot\superpowers\install.ps1"
```

**Bash (macOS/Linux):**
```bash
~/.copilot/superpowers/install.sh
```

### Option 2: Manual Setup

See [.copilot/INSTALL.md](.copilot/INSTALL.md) for step-by-step manual instructions.

### Verify

Start a new Copilot chat and ask: "help me plan this feature" or "let's debug this issue". The agent should read and follow the relevant superpowers skill.

**Detailed docs:** [docs/README.copilot.md](docs/README.copilot.md)

## The Basic Workflow

1. **brainstorming** — Refines rough ideas through questions, explores alternatives, presents design in sections for validation.

2. **using-git-worktrees** — Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.

3. **writing-plans** — Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps.

4. **subagent-driven-development** or **executing-plans** — Dispatches fresh subagent per task with two-stage review, or executes in batches with human checkpoints.

5. **test-driven-development** — Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit.

6. **requesting-code-review** — Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** — Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## Prompt Commands

After installation, use these in Copilot chat:

| Command | Purpose |
|---------|---------|
| `/brainstorm` | Start a Socratic design session |
| `/write-plan` | Create a detailed implementation plan |
| `/execute-plan` | Execute a plan step by step |
| `/debug` | Start systematic root-cause debugging |

## Skills Library

**Testing**
- **test-driven-development** — RED-GREEN-REFACTOR cycle

**Debugging**
- **systematic-debugging** — 4-phase root cause process
- **verification-before-completion** — Ensure it's actually fixed

**Collaboration**
- **brainstorming** — Socratic design refinement
- **writing-plans** — Detailed implementation plans
- **executing-plans** — Batch execution with checkpoints
- **dispatching-parallel-agents** — Concurrent subagent workflows
- **requesting-code-review** — Pre-review checklist
- **receiving-code-review** — Responding to feedback
- **using-git-worktrees** — Parallel development branches
- **finishing-a-development-branch** — Merge/PR decision workflow
- **subagent-driven-development** — Fast iteration with two-stage review

**Meta**
- **writing-skills** — Create new skills following best practices
- **using-superpowers** — Introduction to the skills system

## Tool Mapping

Skills were originally written for Claude Code. Copilot equivalents:

| Skill references | Copilot equivalent |
|-----------------|-------------------|
| `Task` (dispatch subagent) | `runSubagent` |
| `TodoWrite` (task tracking) | `manage_todo_list` |
| `Skill` (invoke a skill) | `read_file` on the SKILL.md path |
| `Read` / `Write` / `Edit` | `read_file` / `create_file` / `replace_string_in_file` or `multi_replace_string_in_file` |
| `Bash` (run commands) | `run_in_terminal` |

Full mapping: [skills/using-superpowers/references/copilot-tools.md](skills/using-superpowers/references/copilot-tools.md)

## Updating

```bash
cd ~/.copilot/superpowers && git pull
```

Then re-run the installer in your project to update prompt files.

## Uninstalling

Run the installer with `-Uninstall` / `--uninstall`:

**PowerShell:**
```powershell
& "$env:USERPROFILE\.copilot\superpowers\install.ps1" -Uninstall
```

**Bash:**
```bash
~/.copilot/superpowers/install.sh --uninstall
```

## Philosophy

- **Test-Driven Development** — Write tests first, always
- **Systematic over ad-hoc** — Process over guessing
- **Complexity reduction** — Simplicity as primary goal
- **Evidence over claims** — Verify before declaring success

## Credits

Forked from [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent.

## License

MIT License — see LICENSE file for details
