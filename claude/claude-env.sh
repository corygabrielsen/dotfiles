# shellcheck shell=bash
# =============================================================================
# claude-env.sh - Claude Code per-command environment setup
# =============================================================================
#
# Sourced by Claude Code before every Bash tool invocation. Activated via
# CLAUDE_ENV_FILE=~/.claude-env.sh (set in ~/.zshenv).
#
# Must be FAST — runs before EVERY command. Avoid forks, slow init.
#
# Behavior:
#   1. Source ~/.profile (profile.d/* — toolchain PATH, locale, etc.)
#      so Claude Bash works regardless of how Claude Code was launched
#      (login terminal, editor terminal, GUI launcher).
#   2. Run direnv AFTER .profile so any .envrc PATH prepends (e.g.,
#      virtualenv `.venv/bin` from `layout python`) end up at the
#      front of PATH, ahead of the toolchain dirs profile.d added.
#   3. Force non-interactive editors/pagers so tools don't hang.
#
# `_PROFILE_LOCAL_LOADED` (exported by profile.d/99-local.sh on first
# source) keeps ~/.profile.local from replaying side effects for every
# Claude command — the user hook runs once per terminal session and
# child Bash invocations skip it.
#
# Symlinked to ~/.claude-env.sh by `make`.
# =============================================================================

# Shared POSIX env (PATH, toolchains, locale, build flags).
# shellcheck disable=SC1091  # symlinked at install time
. "$HOME/.profile"

# direnv: load (or unload) project-specific env. Always called — direnv
# is responsible for both the export side (loading new state when
# entering an .envrc tree) AND the unload side (clearing previous state
# when leaving). Skipping when no .envrc exists below $PWD would leak
# last-project state into commands run elsewhere.
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv export bash 2>/dev/null)"
fi

# Restore an active Python environment (virtualenv or conda) to the
# front of PATH. If the parent shell has one activated, profile.d/20-
# python.sh's pyenv-shim prepend would otherwise put pyenv ahead of the
# environment's `python`. The dedup at the end of ~/.profile keeps both
# copies but in the wrong order. This explicit re-prepend brings the
# environment back to position 1 — direnv export tracks only its own
# state changes, not order, so it can't fix this on its own.
#
# Order: CONDA_PREFIX first, VIRTUAL_ENV last. The common case is a
# venv created inside a conda env — both vars are set, but the user
# wants the venv's python (it's the explicitly-activated inner env).
# Checking VIRTUAL_ENV last lands it at PATH position 1 in that case.
if [ -n "${CONDA_PREFIX:-}" ] && [ -d "$CONDA_PREFIX/bin" ]; then
    case ":$PATH:" in
        ":$CONDA_PREFIX/bin:"*) ;;
        *) PATH="$CONDA_PREFIX/bin:$PATH" ;;
    esac
fi
if [ -n "${VIRTUAL_ENV:-}" ] && [ -d "$VIRTUAL_ENV/bin" ]; then
    case ":$PATH:" in
        ":$VIRTUAL_ENV/bin:"*) ;;
        *) PATH="$VIRTUAL_ENV/bin:$PATH" ;;
    esac
fi

# Non-interactive editors and pagers — prevent tools from spawning
# $EDITOR or $PAGER and hanging on input that will never arrive.
export EDITOR=cat
export VISUAL=cat
export PAGER=cat
export GIT_PAGER=cat
export LESS="-R --quit-if-one-screen --no-init"

export DEBIAN_FRONTEND=noninteractive
export PYTHONUNBUFFERED=1
