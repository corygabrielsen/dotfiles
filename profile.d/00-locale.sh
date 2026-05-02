# shellcheck shell=sh
# =============================================================================
# 00-locale.sh - Locale, hostname, GPG TTY hint
# =============================================================================
#
# HOSTNAME is auto-set by bash but not by zsh; setting it here gives both
# the same view. GPG_TTY must reflect the current shell's tty for
# pinentry. profile.d/ runs at login, so `tty` always succeeds here and
# this branch always sets it — the conditional is just defense-in-depth
# for someone manually re-sourcing this file in a non-tty subshell, in
# which case the inherited value (parent's tty) is left alone since
# that's typically the right thing for child shells of a live terminal.
# =============================================================================

export LANG=en_US.UTF-8

HOSTNAME=$(command uname -n) && export HOSTNAME

if _tty=$(command tty 2>/dev/null); then
    export GPG_TTY="$_tty"
fi
unset _tty
