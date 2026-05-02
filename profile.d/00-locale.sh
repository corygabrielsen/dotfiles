# shellcheck shell=sh
# =============================================================================
# 00-locale.sh - Locale and GPG TTY hint
# =============================================================================
#
# GPG_TTY must reflect the current shell's tty for pinentry; set per-shell.
# Skipped in non-tty contexts (cron, ssh -T, systemd units).
# =============================================================================

export LANG=en_US.UTF-8

GPG_TTY=$(tty 2>/dev/null) && export GPG_TTY
