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

echo "RESULT: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
