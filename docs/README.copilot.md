# GitHub Copilot Compatibility Guide

This repository adapts the instruction-based workflow in [obra/superpowers](https://github.com/obra/superpowers) for GitHub Copilot Chat in VS Code agent mode.

## Integration Model

GitHub Copilot consumes the workflow through native project customization:

- `.github/copilot-instructions.md` introduces the skill system and file locations to each chat.
- `SKILL.md` files contain the workflow instructions Copilot reads when a skill applies.
- `.github/prompts/*.prompt.md` provides four convenient slash-command entry points.
- The tool mapping translates upstream tool names into Copilot agent-mode tools.

The repository does not add a VS Code extension, background service, model provider, or runtime hook.

## Install

Use the project-scoped installer described in the [installation guide](../.copilot/INSTALL.md). It preserves existing instructions outside its managed markers and can be re-run safely when this repository changes.

After installation, a target project contains:

```text
.github/copilot-instructions.md
.github/prompts/brainstorm.prompt.md
.github/prompts/debug.prompt.md
.github/prompts/execute-plan.prompt.md
.github/prompts/write-plan.prompt.md
```

## Skill Activation

Copilot does not load these files merely because they exist in the clone. The generated project instructions tell the agent to inspect the skill catalog before work and to read the applicable `SKILL.md` file.

You can also request a skill directly:

```text
Read and follow ~/.copilot/superpowers/skills/systematic-debugging/SKILL.md for this issue.
```

Actual behavior varies with the selected model, agent-mode tool availability, workspace permissions, and project context. Treat the skills as structured guidance and verify the resulting work normally.

## Prompt Files

| Prompt | Purpose |
| --- | --- |
| `brainstorm.prompt.md` | Turn a rough request into a reviewed design. |
| `write-plan.prompt.md` | Convert an approved design into an implementation plan. |
| `execute-plan.prompt.md` | Work through an existing plan. |
| `debug.prompt.md` | Begin evidence-led diagnosis. |

## Tool Mapping

| Upstream reference | Copilot equivalent |
| --- | --- |
| `Task` | `runSubagent` |
| `TodoWrite` | `manage_todo_list` |
| `Skill` | `read_file` on the relevant `SKILL.md` |
| `Read` | `read_file` |
| `Write` | `create_file` |
| `Edit` | `replace_string_in_file` or `multi_replace_string_in_file` |
| `Bash` | `run_in_terminal` |

See [Copilot tools](../skills/using-superpowers/references/copilot-tools.md) for detailed translations and limitations.

## Known Constraints

- Skill selection is instruction-driven rather than enforced by a plugin runtime.
- Tool names and availability can differ across Copilot versions and VS Code environments.
- Subagents return completed results and may not expose the same interaction model assumed by older skill text.
- A new Git worktree may need to be added to the VS Code workspace before Copilot can access it.
- Installed project instructions reference the cloned skill paths; moving or deleting the clone breaks those references.

## Troubleshooting

### A skill is not being read

- Confirm the project root contains `.github/copilot-instructions.md`.
- Confirm the managed Superpowers block points to the current clone.
- Start a new chat after installing or updating instructions.
- Ask Copilot to read a specific skill path to distinguish discovery problems from tool problems.

### Prompt commands are missing

- Confirm the four files are under the target project's `.github/prompts/` directory.
- Re-run the installer to refresh the prompt files.
- Restart or reload VS Code if prompt discovery has not refreshed.

### Copilot uses an upstream tool name

- Confirm the generated instruction block contains the tool-mapping table.
- Refer Copilot to [Copilot tools](../skills/using-superpowers/references/copilot-tools.md).
- Verify the proposed equivalent is available in the current agent-mode session.

## Validate This Fork

Run the dependency-free local suite from the repository root:

```powershell
pwsh -NoProfile -File tests/test_repository.ps1
```

The suite checks documentation structure, attribution, installer syntax, and PowerShell install/update/uninstall behavior without requiring hosted CI.
