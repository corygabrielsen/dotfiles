# shellcheck shell=sh
# =============================================================================
# 20-python.sh - Python (pyenv) shims on PATH
# =============================================================================
#
# Replicates `pyenv init --path` semantics: prepend $PYENV_ROOT/shims
# (and $PYENV_ROOT/bin) to PATH, then run `pyenv rehash` to refresh
# the shim directory so console scripts installed via pip since the
# last shell start are discoverable.
#
# rehash forks pyenv (~50ms) and ~/.profile is sourced by every Claude
# Bash subprocess via claude-env.sh, so the cost accumulates. We accept
# it because the alternative — skipping rehash here and only running it
# in ~/.zshrc — leaves Claude Bash and other non-interactive contexts
# with stale shims after pip installs, which is the regression that
# pyenv's own `pyenv init --path` default behavior is meant to avoid.
#
# The pyenv shell function (defines `pyenv shell`/`pyenv activate`) is
# set up in ~/.zshenv via `pyenv init - --no-rehash zsh` since that's
# zsh-specific.
# =============================================================================

# `:-` (not `=`) so an inherited PYENV_ROOT wins. Standard idiom for
# tool-prefix env vars — lets `PYENV_ROOT=/alt/pyenv zsh -lc ...` work
# without surgery here. The corner case (alternate $HOME with inherited
# PYENV_ROOT pointing at the previous account's tree) is the user's
# responsibility to clear before launching the subshell.
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

[ -d "$PYENV_ROOT/bin" ] && PATH="$PYENV_ROOT/bin:$PATH"

# Find the pyenv binary. Five tiers, fastest first; the last is a PATH
# walk via command -v which covers any install layout (nix, asdf, custom
# prefix) at the cost of ~20ms when pyenv isn't installed at all.
#   1. $PYENV_ROOT/bin/pyenv     — curl|sh installer (canonical layout)
#   2. $HOMEBREW_PREFIX/bin/pyenv — brew install pyenv (10-homebrew.sh sets $HOMEBREW_PREFIX first)
#   3. /usr/local/bin/pyenv      — manual install or older system layout
#   4. /usr/bin/pyenv            — distro package (apt, dnf, etc.)
#   5. command -v pyenv          — Nix profiles, asdf shims, custom prefixes
_pyenv_bin=""
if   [ -x "$PYENV_ROOT/bin/pyenv" ];                  then _pyenv_bin="$PYENV_ROOT/bin/pyenv"
elif [ -x "${HOMEBREW_PREFIX:-/nope}/bin/pyenv" ];    then _pyenv_bin="$HOMEBREW_PREFIX/bin/pyenv"
elif [ -x /usr/local/bin/pyenv ];                     then _pyenv_bin=/usr/local/bin/pyenv
elif [ -x /usr/bin/pyenv ];                           then _pyenv_bin=/usr/bin/pyenv
elif command -v pyenv >/dev/null 2>&1;                then _pyenv_bin=$(command -v pyenv)
fi

# `--path sh` for POSIX-clean output (auto-detect can pick bash and emit
# `[[ ]]`/array constructs that dash rejects). Output prepends shims to
# PATH and runs `pyenv rehash`.
if [ -n "$_pyenv_bin" ]; then
    eval "$("$_pyenv_bin" init --path sh)"
fi
unset _pyenv_bin
