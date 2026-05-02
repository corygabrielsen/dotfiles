# shellcheck shell=sh
# =============================================================================
# 99-local.sh - Per-machine override
# =============================================================================
#
# Sources ~/.profile.local if present. Gitignored — not in the repo.
#
# Best-effort process-tree guard: ~/.profile.local can contain arbitrary
# user logic (one-shot setup, agent launches, log writes). Without a
# guard, the file would replay on every Claude Bash subprocess
# (claude-env.sh sources ~/.profile in a fresh bash per tool call) and
# on every nested zsh (~/.zshenv sources ~/.profile, by design, so
# editor terminals and `zsh -c` get the toolchain PATH).
#
# `_PROFILE_LOCAL_LOADED` is exported, so descendant shells inherit the
# flag and skip. The hook fires once per terminal session: the first
# login shell sets the guard; everything that descends from it inherits
# and skips.
#
# LIMITATION: the guard relies on environment inheritance, so it only
# suppresses replay within a process tree rooted at a shell that
# already ran ~/.profile. Claude (or any process) launched from a non-
# shell parent — desktop launcher, Finder/Spotlight on macOS,
# Raycast/Alfred, systemd-user unit — starts each Bash subprocess from
# a fresh root, so the guard isn't set and ~/.profile.local fires
# again before every command. There's no purely-shell-level fix for
# that case (env vars don't propagate to siblings); the workaround is
# to write ~/.profile.local idempotently — guard the side-effects on a
# tmpfile sentinel or `[ -z "$ALREADY_DONE" ]` check inside the file
# itself.
#
# Functions, aliases, and non-exported variables defined in
# ~/.profile.local also propagate "set once, then nothing" — child
# shells don't get them re-defined. That's inherent to the design: env
# vars survive `exec`, functions don't. Put functions and aliases in
# ~/.zshrc.local instead, where they're meant to live.
# =============================================================================

if [ -z "${_PROFILE_LOCAL_LOADED:-}" ]; then
    export _PROFILE_LOCAL_LOADED=1
    # shellcheck disable=SC1091  # per-machine, not part of repo
    [ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
fi
