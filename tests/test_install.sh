#!/usr/bin/env bash
# Install/uninstall lifecycle test for install.sh, mirroring the PowerShell
# lifecycle checks in test_repository.ps1 plus prompt-file ownership.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
passed=0
failed=0

check() { # name, command...
    local name="$1"; shift
    if "$@"; then passed=$((passed + 1)); echo "PASS: $name"
    else failed=$((failed + 1)); echo "FAIL: $name"; fi
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/superpowers-install-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

run_install()   { (cd "$1" && bash "$ROOT/install.sh" >/dev/null 2>&1); }
run_uninstall() { (cd "$1" && bash "$ROOT/install.sh" --uninstall >/dev/null 2>&1); }
count_prompts() { ls -1 "$1/.github/prompts"/*.prompt.md 2>/dev/null | wc -l | tr -d ' '; }

# --- 1. idempotent install, uninstall preserves existing guidance ----------
P1="$TMP/p1"; mkdir -p "$P1/.github"
printf 'Existing project guidance.' > "$P1/.github/copilot-instructions.md"
run_install "$P1"; run_install "$P1"
markers=$(grep -c 'SUPERPOWERS:START' "$P1/.github/copilot-instructions.md")
check "Bash installer is idempotent and copies four prompts" \
    test "$markers" = 1 -a "$(count_prompts "$P1")" = 4
run_uninstall "$P1"
check "Bash uninstaller preserves existing guidance and removes its prompts" \
    test "$(cat "$P1/.github/copilot-instructions.md")" = 'Existing project guidance.' \
    -a "$(count_prompts "$P1")" = 0
check "Bash uninstaller leaves no prompts directory behind" test ! -e "$P1/.github/prompts"

# --- 2. a project's own same-named prompt is neither overwritten nor deleted -
P2="$TMP/p2"; mkdir -p "$P2/.github/prompts"
printf 'MY OWN DEBUG PROMPT' > "$P2/.github/prompts/debug.prompt.md"
run_install "$P2"
check "install keeps a pre-existing same-named prompt" \
    test "$(cat "$P2/.github/prompts/debug.prompt.md")" = 'MY OWN DEBUG PROMPT'
check "install still adds the other three prompts" test "$(count_prompts "$P2")" = 4
run_uninstall "$P2"
check "uninstall does not delete a prompt the installer did not create" \
    test "$(cat "$P2/.github/prompts/debug.prompt.md")" = 'MY OWN DEBUG PROMPT'
check "uninstall removes only the prompts it installed" test "$(count_prompts "$P2")" = 1

# --- 3. a prompt the user edited after install survives uninstall ----------
P3="$TMP/p3"; mkdir -p "$P3"
run_install "$P3"
printf 'EDITED' >> "$P3/.github/prompts/brainstorm.prompt.md"
run_uninstall "$P3"
check "uninstall keeps an installed prompt the user edited" \
    test -f "$P3/.github/prompts/brainstorm.prompt.md" -a "$(count_prompts "$P3")" = 1

# --- 4. re-install does not clobber an installed prompt the user edited -----
P4="$TMP/p4"; mkdir -p "$P4"
run_install "$P4"
printf 'my tweak' > "$P4/.github/prompts/write-plan.prompt.md"
run_install "$P4"
check "re-install keeps an installed prompt the user edited"     test "$(cat "$P4/.github/prompts/write-plan.prompt.md")" = 'my tweak'

# --- 5. legacy install (no manifest): byte-identical prompts are adopted ----
P5="$TMP/p5"; mkdir -p "$P5/.github/prompts"
cp "$ROOT/.copilot/prompts/"*.prompt.md "$P5/.github/prompts/"
printf 'MINE' > "$P5/.github/prompts/debug.prompt.md"
run_uninstall "$P5"
check "legacy uninstall removes identical copies and keeps different ones"     test "$(count_prompts "$P5")" = 1 -a "$(cat "$P5/.github/prompts/debug.prompt.md")" = MINE

# --- 6. start marker without end marker: abort, keep later content ----------
TRUNC=$'Head.\n<!-- SUPERPOWERS:START -->\nhand edited\nLater project instructions.\n'
P6="$TMP/p6"; mkdir -p "$P6/.github"
printf '%s' "$TRUNC" > "$P6/.github/copilot-instructions.md"
run_install "$P6"; rc=$?
check "install aborts when the end marker is missing" test "$rc" -ne 0
check "install leaves a file with no end marker unchanged" \
    test "$(cat "$P6/.github/copilot-instructions.md")" = "${TRUNC%$'\n'}"
P7="$TMP/p7"; mkdir -p "$P7/.github"
printf '%s' "$TRUNC" > "$P7/.github/copilot-instructions.md"
run_uninstall "$P7"; rc=$?
check "uninstall aborts when the end marker is missing" test "$rc" -ne 0
check "uninstall leaves a file with no end marker unchanged" \
    test "$(cat "$P7/.github/copilot-instructions.md")" = "${TRUNC%$'\n'}"

# --- 7. both markers present: update and uninstall still work ---------------
P8="$TMP/p8"; mkdir -p "$P8/.github"
printf 'Head.\n' > "$P8/.github/copilot-instructions.md"
run_install "$P8"
sed -i 's/^Head\.$/Head changed./' "$P8/.github/copilot-instructions.md"
printf '\nTail.\n' >>"$P8/.github/copilot-instructions.md"
run_install "$P8"
f8="$P8/.github/copilot-instructions.md"
check "update with both markers keeps surrounding text and one block" \
    test "$(grep -c 'SUPERPOWERS:START' "$f8")" = 1 -a "$(grep -c 'SUPERPOWERS:END' "$f8")" = 1 \
    -a "$(head -1 "$f8")" = 'Head changed.' -a "$(tail -1 "$f8")" = 'Tail.'
run_uninstall "$P8"
check "uninstall with both markers removes the block and keeps the rest" \
    test "$(grep -c 'SUPERPOWERS' "$f8")" = 0 -a "$(head -1 "$f8")" = 'Head changed.' -a "$(tail -1 "$f8")" = 'Tail.'

# --- 8. no-change repeat versus a real block update -----------------------
P9="$TMP/p9"; mkdir -p "$P9"
run_install "$P9"
f9="$P9/.github/copilot-instructions.md"
cp "$f9" "$TMP/before-repeat.md"
repeat_output=$(cd "$P9" && bash "$ROOT/install.sh"); rc=$?
check "repeat install exits successfully" test "$rc" = 0
check "repeat install leaves instruction bytes unchanged" cmp -s "$f9" "$TMP/before-repeat.md"
check "repeat install reports unchanged content" \
    test "$(printf '%s\n' "$repeat_output" | grep -c '^  Unchanged superpowers block in copilot-instructions.md$')" = 1 \
    -a "$(printf '%s\n' "$repeat_output" | grep -c '^  Updated superpowers block')" = 0
if [[ "$repeat_output" != *'Unchanged superpowers block'* ]]; then
    printf '%s\n' "$repeat_output"
fi
sed -i 's/^## Superpowers$/## SUPERPOWERS/' "$f9"
update_output=$(cd "$P9" && bash "$ROOT/install.sh"); rc=$?
check "changed block install exits successfully" test "$rc" = 0
check "changed block install reports updated content" \
    test "$(printf '%s\n' "$update_output" | grep -c '^  Updated superpowers block in copilot-instructions.md$')" = 1
check "changed block install restores current instructions" cmp -s "$f9" "$TMP/before-repeat.md"

echo "RESULT: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
