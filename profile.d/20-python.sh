# shellcheck shell=sh
# =============================================================================
# 20-python.sh - Python (pyenv) shims on PATH
# =============================================================================
#
# `pyenv init --path` is the env-layer init: shims only, no completions.
# Full `pyenv init -` runs from ~/.zshrc for interactive use.
# =============================================================================

export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
fi
