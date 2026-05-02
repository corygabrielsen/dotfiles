# shellcheck shell=sh
# shellcheck disable=SC3013  # -nt is supported by bash/dash/ash/busybox
# =============================================================================
# 10-homebrew.sh - Homebrew / Linuxbrew shellenv (cached)
# =============================================================================
#
# Numbered 10 so brew loads BEFORE toolchain shims (20-node, 20-python,
# etc). Toolchains then prepend after, ending at the front of PATH — so
# nvm's node and pyenv's python beat brew-installed copies. Reverse the
# numbering and brew wins instead.
#
# `brew shellenv` forks brew on every shell startup (~15-20ms). Output is
# static for a given install, so cache to ~/.cache/brew-shellenv.sh and
# regenerate when:
#   - Cache is missing
#   - Brew binary is newer than cache (brew was upgraded)
#   - Cache was generated for a different brew install (header mismatch —
#     handles e.g. Intel → Apple Silicon migration where the new binary
#     may be older than the previous cache).
#
# Limitation: `bin/brew` mtime is the invalidation signal, but the actual
# shellenv text comes from `Library/Homebrew/cmd/shellenv.rb` under the
# brew tree. A `brew update` that rewrites shellenv without bumping
# `bin/brew` mtime won't trip the cache check — a manual
# `rm ~/.cache/brew-shellenv.sh` is needed in that rare case. We don't
# stat every Library file because it would defeat the cache's purpose.
# =============================================================================

case "$(command uname)" in
    Darwin)
        if   [ -x /opt/homebrew/bin/brew ]; then _brew=/opt/homebrew/bin/brew
        elif [ -x /usr/local/bin/brew ];    then _brew=/usr/local/bin/brew
        else                                     _brew=""
        fi
        ;;
    Linux)
        if   [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then _brew=/home/linuxbrew/.linuxbrew/bin/brew
        elif [ -x "$HOME/.linuxbrew/bin/brew" ];         then _brew="$HOME/.linuxbrew/bin/brew"
        else                                                  _brew=""
        fi
        ;;
    *)  _brew="" ;;
esac

if [ -n "$_brew" ]; then
    _cache="$HOME/.cache/brew-shellenv.sh"
    _stamp="# brew=$_brew"
    _need_regen=0
    if [ ! -f "$_cache" ]; then
        _need_regen=1
    elif [ "$_brew" -nt "$_cache" ]; then
        _need_regen=1
    elif ! command head -1 "$_cache" 2>/dev/null | command grep -qxF "$_stamp"; then
        _need_regen=1
    fi

    _regen_failed=0
    if [ "$_need_regen" = 1 ]; then
        # Capture brew shellenv output BEFORE writing to disk so we can
        # validate it. brew shellenv emits empty output when
        # HOMEBREW_PREFIX is already set (e.g., re-source within a
        # process tree) and caching empty output would leave fresh
        # shells with no brew env at all.
        _output=$("$_brew" shellenv sh 2>/dev/null) || _regen_failed=1
        if [ -z "$_output" ]; then
            _regen_failed=1
        fi

        if [ "$_regen_failed" = 0 ]; then
            # Explicit `sh` (above) so the cache is POSIX-clean for any
            # shell. Without it brew autodetects the parent shell and
            # may emit zsh-only syntax (`fpath[1,0]=...`) that dash
            # rejects. zsh fpath setup lives in ~/.zshenv instead.
            #
            # Write to a PID-suffixed temp file and rename on success —
            # POSIX mv is atomic, so concurrent shells never see a
            # partial cache, and a failing brew shellenv leaves the
            # previous cache intact. Stderr suppressed so read-only-HOME
            # contexts load silently.
            _tmp="${_cache}.tmp.$$"
            if command mkdir -p "$HOME/.cache" 2>/dev/null \
                && printf '%s\n%s\n' "$_stamp" "$_output" > "$_tmp" 2>/dev/null
            then
                command mv -f "$_tmp" "$_cache" 2>/dev/null || _regen_failed=1
            else
                command rm -f "$_tmp" 2>/dev/null
                _regen_failed=1
            fi
        fi
    fi

    if [ "$_regen_failed" = 1 ] && [ -n "${_output:-}" ]; then
        # Got fresh output but couldn't cache it. Use what we have.
        eval "$_output"
    elif [ "$_regen_failed" = 1 ]; then
        # Couldn't get fresh output AND existing cache (if any) is
        # suspect. Eval direct so this session still has brew env.
        eval "$("$_brew" shellenv sh)"
    elif [ -f "$_cache" ]; then
        # shellcheck disable=SC1090  # cache, regenerated on brew updates
        . "$_cache"
    fi
fi

unset _brew _cache _stamp _need_regen _tmp _regen_failed _output
