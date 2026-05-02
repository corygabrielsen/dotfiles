#!/bin/sh
# =============================================================================
# test.sh - Validate dotfiles install inside a container
# =============================================================================
#
# Runs inside a container that has the dotfiles repo at $HOME/dotfiles.
# Exits 0 on success, nonzero with a clear message on first failure.
#
# Designed to grow with the dotfiles: phases 3-5 are gated by the presence
# of ~/.profile.d/, so the same script remains correct as profile.d/,
# secrets/, and bootstrap/ get added in subsequent commits.
#
# Phases:
#   1. install       — `make` + `make require` + idempotence
#   2. shell-source  — sourcing ~/.profile under bash, zsh, dash
#   3. profile.d     — POSIX syntax check on every file
#   4. path-load     — expected entries appear on PATH
#   5. toolchains    — installed toolchains end up on PATH
#
# Driven by: test/run.sh / `make test-container`.
# =============================================================================

set -eu

REPO="$HOME/dotfiles"
LOG=$(mktemp -t dotfiles-test.XXXXXX)
trap 'rm -f "$LOG"' EXIT


# =============================================================================
# Output helpers
# =============================================================================

# Colors — pre-decoded once, used with %s. Disabled if stdout isn't a TTY.
if [ -t 1 ]; then
    ESC=$(printf '\033')
    DIM="${ESC}[2m"; CYAN="${ESC}[0;36m"; RED="${ESC}[0;31m"; GREEN="${ESC}[0;32m"; ENDC="${ESC}[0m"
else
    DIM=""; CYAN=""; RED=""; GREEN=""; ENDC=""
fi

log()  { printf '%s[test]%s %s\n' "$CYAN" "$ENDC" "$*"; }
skip() { printf '%s[skip]%s %s\n' "$DIM"  "$ENDC" "$*"; }
pass() { printf '%s[ ok ]%s %s\n' "$GREEN" "$ENDC" "$*"; }
fail() { printf '%s[FAIL]%s %s\n' "$RED"   "$ENDC" "$*" >&2; exit 1; }

# run <description> <command...>
# Logs description, runs command capturing combined output, prints the
# captured output to stderr on failure (so CI logs show the real error).
run() {
    desc="$1"; shift
    log "$desc"
    "$@" >"$LOG" 2>&1 || { cat "$LOG" >&2; fail "$desc"; }
    pass "$desc"
}


# =============================================================================
# Phase 1: install
# =============================================================================
#
# `make require` is the read-only fail-fast validator. Use it (not
# `make doctor`, which only prints diagnostics) so a regressed second
# `make` is actually caught.

cd "$REPO" || fail "repo not found at $REPO"

run "make"                            make
run "make require"                    make require
run "make (idempotence)"              make
run "make require (after re-run)"     make require


# =============================================================================
# Phase 2: shell-source
# =============================================================================
#
# Sourcing ~/.profile must succeed under every shell we ship for. If a shell
# isn't installed we skip — the test image controls which are present.

for sh_name in bash zsh dash; do
    if ! command -v "$sh_name" >/dev/null 2>&1; then
        skip "$sh_name not installed in image"
        continue
    fi
    run "$sh_name sources ~/.profile" "$sh_name" -c '. ~/.profile'
done


# =============================================================================
# Phases 3-5: profile.d/-gated
# =============================================================================
#
# All three phases require ~/.profile.d/ to exist and be wired into the env
# loop. They share a single capture of PATH-after-sourcing, computed once.

if [ ! -d "$HOME/.profile.d" ]; then
    skip "profile.d/ not present (phases 3-5)"
    exit 0
fi


# Phase 3: every file in ~/.profile.d/ must parse under dash (the strictest
# in-use POSIX shell). `dash -n` is parse-only — no execution.
log "POSIX syntax-check on ~/.profile.d/*.sh"
for f in "$HOME"/.profile.d/*.sh; do
    [ -e "$f" ] || continue
    dash -n "$f" || fail "POSIX syntax check failed: $f"
done
pass "all profile.d/*.sh files parse under dash"


# Capture PATH once — sourcing ~/.profile in a clean bash subshell is
# expensive (one fork) but only paid here, then reused below for both
# phase 4 (dir-on-PATH check) and phase 5 (toolchain reachability).
log "capturing PATH after sourcing ~/.profile"
actual_path=$(bash -c '. ~/.profile && printf "%s" "$PATH"') \
    || fail "could not source ~/.profile under bash to capture PATH"


# Phase 4: every entry whose target dir exists must appear on PATH. Missing
# dirs are silently skipped (e.g., bun not installed -> ~/.bun/bin not
# checked). Per-entry pass output replaces a closing summary.
log "PATH contains expected entries"
for entry in \
    "$HOME/.local/bin" \
    "/usr/local/go/bin" \
    "$HOME/.bun/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.elan/bin" \
    "$HOME/.opencode/bin"
do
    [ -d "$entry" ] || continue
    case ":$actual_path:" in
        *":$entry:"*) pass "PATH contains $entry" ;;
        *)            fail "PATH missing $entry after sourcing ~/.profile" ;;
    esac
done


# Phase 5: installed toolchains must resolve under the captured PATH.
# Cross-checks Phase 4 from the tool side — Phase 4 verifies dir-on-PATH;
# Phase 5 verifies executable-resolves-via-PATH.
log "toolchains reachable via PATH"
for tool in node go cargo bun; do
    command -v "$tool" >/dev/null 2>&1 || { skip "$tool not installed"; continue; }
    if PATH="$actual_path" command -v "$tool" >/dev/null 2>&1; then
        pass "$tool resolves via PATH"
    else
        fail "$tool installed but not reachable via PATH from ~/.profile"
    fi
done


# =============================================================================
# Done
# =============================================================================

printf '\n%sall tests passed%s\n' "$GREEN" "$ENDC"
