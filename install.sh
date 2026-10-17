#!/usr/bin/env bash
#
# Install Superpowers skills into the current project for GitHub Copilot.
#
# Usage:
#   ~/.copilot/superpowers/install.sh              # Install
#   ~/.copilot/superpowers/install.sh --uninstall   # Remove
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SUPERPOWERS_ROOT="$SCRIPT_DIR"
PROJECT_ROOT="$(pwd)"

# Determine skills path prefix
HOME_COPILOT_PATH="$HOME/.copilot/superpowers"
if [ "$SUPERPOWERS_ROOT" = "$HOME_COPILOT_PATH" ]; then
    SKILLS_PREFIX="~/.copilot/superpowers/skills"
else
    SKILLS_PREFIX="$SUPERPOWERS_ROOT/skills"
fi

GITHUB_DIR="$PROJECT_ROOT/.github"
PROMPTS_DIR="$GITHUB_DIR/prompts"
INSTRUCTIONS_FILE="$GITHUB_DIR/copilot-instructions.md"
# Records every prompt file this installer wrote ("<sha256>  <name>"), so
# install and uninstall only touch files Superpowers owns.
MANIFEST="$PROMPTS_DIR/.superpowers-manifest"

START_MARKER='<!-- SUPERPOWERS:START -->'
END_MARKER='<!-- SUPERPOWERS:END -->'

file_hash() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

# Hash recorded for a prompt name in the manifest (empty when not owned).
manifest_hash() {
    [ -f "$MANIFEST" ] || return 0
    awk -v n="$1" '$2 == n { print $1 }' "$MANIFEST"
}

manifest_set() { # name hash
    local tmp="$MANIFEST.tmp"
    { [ -f "$MANIFEST" ] && awk -v n="$1" '$2 != n' "$MANIFEST"; printf '%s  %s
' "$2" "$1"; } > "$tmp"
    mv "$tmp" "$MANIFEST"
}

generate_block() {
    cat <<BLOCK
$START_MARKER
## Superpowers

You have superpowers — a structured software development workflow system.

**Before starting any task**, check if a skill applies. If there is even a 1% chance a skill is relevant, read it.

### Loading Skills

To load a skill, use \`read_file\` on the SKILL.md file path below. Read the skill content and follow the workflow it describes.

#### Core Skill (read this first on any new task)

- **using-superpowers**: $SKILLS_PREFIX/using-superpowers/SKILL.md

#### Available Skills

- **brainstorming**: $SKILLS_PREFIX/brainstorming/SKILL.md
- **writing-plans**: $SKILLS_PREFIX/writing-plans/SKILL.md
- **executing-plans**: $SKILLS_PREFIX/executing-plans/SKILL.md
- **subagent-driven-development**: $SKILLS_PREFIX/subagent-driven-development/SKILL.md
- **test-driven-development**: $SKILLS_PREFIX/test-driven-development/SKILL.md
- **systematic-debugging**: $SKILLS_PREFIX/systematic-debugging/SKILL.md
- **verification-before-completion**: $SKILLS_PREFIX/verification-before-completion/SKILL.md
- **requesting-code-review**: $SKILLS_PREFIX/requesting-code-review/SKILL.md
- **receiving-code-review**: $SKILLS_PREFIX/receiving-code-review/SKILL.md
- **using-git-worktrees**: $SKILLS_PREFIX/using-git-worktrees/SKILL.md
- **finishing-a-development-branch**: $SKILLS_PREFIX/finishing-a-development-branch/SKILL.md
- **dispatching-parallel-agents**: $SKILLS_PREFIX/dispatching-parallel-agents/SKILL.md
- **writing-skills**: $SKILLS_PREFIX/writing-skills/SKILL.md

### Tool Mapping

Skills reference Claude Code tool names. Use these Copilot equivalents:

| Claude Code tool | Copilot equivalent |
|-----------------|-------------------|
| \`Task\` (dispatch subagent) | \`runSubagent\` |
| \`TodoWrite\` (task tracking) | \`manage_todo_list\` |
| \`Skill\` (invoke a skill) | \`read_file\` on the SKILL.md path |
| \`Read\` (read files) | \`read_file\` |
| \`Write\` (create files) | \`create_file\` |
| \`Edit\` (edit files) | \`replace_string_in_file\` or \`multi_replace_string_in_file\` |
| \`Bash\` (run commands) | \`run_in_terminal\` |

Full mapping: $SKILLS_PREFIX/using-superpowers/references/copilot-tools.md
$END_MARKER
BLOCK
}

install_superpowers() {
    echo "Installing Superpowers into: $PROJECT_ROOT"

    # Create .github directory
    mkdir -p "$GITHUB_DIR"

    # Generate the block
    BLOCK=$(generate_block)

    if [ -f "$INSTRUCTIONS_FILE" ]; then
        if grep -qF "$START_MARKER" "$INSTRUCTIONS_FILE"; then
            # Replace existing block
            # Use awk to replace between markers
            awk -v block="$BLOCK" -v start="$START_MARKER" -v end="$END_MARKER" '
                $0 ~ start { print block; skip=1; next }
                $0 ~ end { skip=0; next }
                !skip { print }
            ' "$INSTRUCTIONS_FILE" > "${INSTRUCTIONS_FILE}.tmp"
            mv "${INSTRUCTIONS_FILE}.tmp" "$INSTRUCTIONS_FILE"
            echo "  Updated superpowers block in copilot-instructions.md"
        else
            # Append to existing file
            printf '\n\n%s' "$BLOCK" >> "$INSTRUCTIONS_FILE"
            echo "  Appended superpowers block to copilot-instructions.md"
        fi
    else
        echo "$BLOCK" > "$INSTRUCTIONS_FILE"
        echo "  Created copilot-instructions.md"
    fi

    # Copy prompt files
    SOURCE_PROMPTS="$SUPERPOWERS_ROOT/.copilot/prompts"
    if [ -d "$SOURCE_PROMPTS" ]; then
        mkdir -p "$PROMPTS_DIR"
        installed=0; kept=0
        for src in "$SOURCE_PROMPTS"/*.prompt.md; do
            name="$(basename "$src")"
            dest="$PROMPTS_DIR/$name"
            src_hash="$(file_hash "$src")"
            if [ ! -e "$dest" ]; then
                cp "$src" "$dest"; manifest_set "$name" "$src_hash"; installed=$((installed + 1))
                continue
            fi
            dest_hash="$(file_hash "$dest")"
            owned_hash="$(manifest_hash "$name")"
            if [ "$dest_hash" = "$src_hash" ]; then
                # Identical to ours: adopt it (covers installs made before the manifest existed).
                manifest_set "$name" "$src_hash"; installed=$((installed + 1))
            elif [ -n "$owned_hash" ] && [ "$owned_hash" = "$dest_hash" ]; then
                # Ours and unmodified: refresh to the current version.
                cp "$src" "$dest"; manifest_set "$name" "$src_hash"; installed=$((installed + 1))
            else
                echo "  Kept existing .github/prompts/$name (not installed by Superpowers, or edited since)"
                kept=$((kept + 1))
            fi
        done
        echo "  Installed $installed prompt files to .github/prompts/ (kept $kept existing)"
    fi

    echo ""
    echo "Superpowers installed! Start a new Copilot chat to use them."
    echo "  Try: /brainstorm, /write-plan, /execute-plan, /debug"
}

uninstall_superpowers() {
    echo "Removing Superpowers from: $PROJECT_ROOT"

    # Remove superpowers block from copilot-instructions.md
    if [ -f "$INSTRUCTIONS_FILE" ]; then
        if grep -qF "$START_MARKER" "$INSTRUCTIONS_FILE"; then
            awk -v start="$START_MARKER" -v end="$END_MARKER" '
                $0 ~ start { skip=1; next }
                $0 ~ end { skip=0; next }
                !skip { print }
            ' "$INSTRUCTIONS_FILE" > "${INSTRUCTIONS_FILE}.tmp"

            # Remove leading/trailing blank lines
            sed -e '/./,$!d' -e :a -e '/^\s*$/{ $d; N; ba; }' "${INSTRUCTIONS_FILE}.tmp" > "${INSTRUCTIONS_FILE}.tmp2"

            if [ -s "${INSTRUCTIONS_FILE}.tmp2" ]; then
                mv "${INSTRUCTIONS_FILE}.tmp2" "$INSTRUCTIONS_FILE"
                rm -f "${INSTRUCTIONS_FILE}.tmp"
                echo "  Removed superpowers block from copilot-instructions.md"
            else
                rm -f "$INSTRUCTIONS_FILE" "${INSTRUCTIONS_FILE}.tmp" "${INSTRUCTIONS_FILE}.tmp2"
                echo "  Removed copilot-instructions.md (was empty)"
            fi
        else
            echo "  No superpowers block found in copilot-instructions.md"
        fi
    fi

    # Remove only the prompt files this installer owns and the user has not edited.
    SOURCE_PROMPTS="$SUPERPOWERS_ROOT/.copilot/prompts"
    for f in brainstorm.prompt.md write-plan.prompt.md execute-plan.prompt.md debug.prompt.md; do
        path="$PROMPTS_DIR/$f"
        [ -f "$path" ] || continue
        owned_hash="$(manifest_hash "$f")"
        current="$(file_hash "$path")"
        # No manifest entry (pre-manifest install): owned only if identical to our copy.
        if [ -z "$owned_hash" ] && [ -f "$SOURCE_PROMPTS/$f" ]; then
            owned_hash="$(file_hash "$SOURCE_PROMPTS/$f")"
        fi
        if [ -n "$owned_hash" ] && [ "$owned_hash" = "$current" ]; then
            rm "$path"
            echo "  Removed .github/prompts/$f"
        else
            echo "  Kept .github/prompts/$f (not installed by Superpowers, or edited since)"
        fi
    done
    rm -f "$MANIFEST" "$MANIFEST.tmp"

    # Clean up empty directories
    [ -d "$PROMPTS_DIR" ] && rmdir "$PROMPTS_DIR" 2>/dev/null || true

    echo ""
    echo "Superpowers removed."
}

# Main
case "${1:-}" in
    --uninstall|-u)
        uninstall_superpowers
        ;;
    *)
        install_superpowers
        ;;
esac
