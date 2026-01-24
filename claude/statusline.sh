#!/bin/bash
# =============================================================================
# Claude Code Status Line
# =============================================================================
#
# Custom status line for Claude Code CLI that mirrors zsh PS1 styling and adds
# session metrics. Designed to feel native while surfacing important warnings.
#
# CONFIGURATION
#   ~/.claude/settings.json:
#   {
#     "statusLine": {
#       "type": "command",
#       "command": "~/.claude/statusline.sh"
#     }
#   }
#
# PROTOCOL
#   Input:  JSON on stdin with session context (see INPUT SCHEMA below)
#   Output: Single line of ANSI-colored text on stdout
#
# INPUT SCHEMA (partial - only fields we use)
#   {
#     "workspace": { "current_dir": "/path/to/cwd" },
#     "context_window": { "used_percentage": 42 },
#     "cost": {
#       "total_cost_usd": 12.34,
#       "total_lines_added": 100,
#       "total_lines_removed": 50
#     }
#   }
#
# OUTPUT FORMAT
#   Normal:  ~/code/project (master)  42%  +100 -50
#   Warning: ~/code/project (master)  42%  +100 -50  ⚠ API $12.34
#
# DESIGN PHILOSOPHY
#   - Directory/git colors match user's zsh PS1 (visual consistency)
#   - Metadata (context %, lines) uses subdued colors (information, not alerts)
#   - Auth warning only appears when NOT on max subscription (alert on exception)
#   - Context % uses gradient: green → yellow → orange → red as it fills
#
# WHY CHECK AUTH?
#   Claude Code can authenticate via OAuth (flat monthly subscription) or API key
#   (per-token billing). Accidentally using API key can cost hundreds of dollars.
#   The warning makes auth status visible at a glance.
#
# =============================================================================

set -o errexit
set -o nounset
set -o pipefail

# =============================================================================
# Colors
# =============================================================================
#
# Three color categories:
#   1. PS1 colors - match user's zsh prompt for visual consistency
#   2. Metadata colors - subdued, informational (not attention-grabbing)
#   3. Gradient colors - context % heat map (green=safe, red=nearly full)

# PS1 colors (vibrant - user expects these from their shell prompt)
BLUE="\033[0;34m"
LIME="\033[38;5;154m"
TURQUOISE="\033[38;5;45m"
ORANGE="\033[38;5;166m"
MAGENTA="\033[0;35m"
PURPLE="\033[38;5;141m"
BRIGHT_RED="\033[1;31m"
BRIGHT_GREEN="\033[38;5;118m"
CYAN="\033[0;36m"
YELLOWISH="\033[38;5;220m"

# Metadata colors (subdued - information, not alerts)
DIM="\033[2m"
ENDC="\033[0m"
SUBTLE_GREEN="\033[38;5;108m"
SUBTLE_RED="\033[38;5;131m"

# Context gradient (visual heat map as context fills up)
CTX_GREEN="\033[38;5;108m"        # 0-24%   - plenty of room
CTX_YELLOW_GREEN="\033[38;5;149m" # 25-49%  - comfortable
CTX_YELLOW="\033[38;5;179m"       # 50-64%  - getting warm
CTX_ORANGE="\033[38;5;208m"       # 65-79%  - caution
CTX_RED_ORANGE="\033[38;5;203m"   # 80-89%  - warning
CTX_RED="\033[38;5;196m"          # 90-100% - critical

# =============================================================================
# Input Parsing
# =============================================================================

# Read JSON input from Claude Code (passed via stdin)
input=$(cat)

# Extract fields using jq. The // operator provides defaults for missing fields.
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' | xargs printf "%.2f")
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# =============================================================================
# Directory Display
# =============================================================================
#
# Matches parse_homedir() from .zshrc for visual consistency with shell prompt.
# Three cases:
#   ~           - home directory (blue)
#   ~/subdir    - under home (lime ~ + turquoise path)
#   /elsewhere  - outside home (orange full path)

dir="$cwd"
if [[ "$dir" == "$HOME" ]]; then
    dir_display=$(printf '%b~%b' "$BLUE" "$ENDC")
elif [[ "$dir" == "$HOME/"* ]]; then
    subdir="${dir#$HOME}"
    dir_display=$(printf '%b~%b%b%s%b' "$LIME" "$ENDC" "$TURQUOISE" "$subdir" "$ENDC")
else
    dir_display=$(printf '%b%s%b' "$ORANGE" "$dir" "$ENDC")
fi

# =============================================================================
# Git Status
# =============================================================================
#
# Matches parse_git() and parse_git_changes() from .zshrc.
#
# Branch colors:
#   - Detached HEAD (sha)  → bright red (unusual state, draw attention)
#   - master               → magenta (primary branch)
#   - other branches       → purple (feature work)
#
# Change indicators:
#   - +N (green)  → staged files
#   - +N (cyan)   → untracked files
#   - ~N (yellow) → modified files

git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)

    if [ -z "$branch" ]; then
        git_sha=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
        branch_display=$(printf '%b(%s)%b' "$BRIGHT_RED" "$git_sha" "$ENDC")
    elif [ "$branch" = "master" ]; then
        branch_display=$(printf '%b(%s)%b' "$MAGENTA" "$branch" "$ENDC")
    else
        branch_display=$(printf '%b(%s)%b' "$PURPLE" "$branch" "$ENDC")
    fi

    # Count changes (suppress errors for non-git directories)
    num_added=$(git -C "$cwd" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    num_untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    num_modified=$(git -C "$cwd" diff --name-only 2>/dev/null | wc -l | tr -d ' ')

    changes=""
    [ "$num_added" -gt 0 ] && changes=$(printf '%s%b+%s%b' "$changes" "$BRIGHT_GREEN" "$num_added" "$ENDC")
    [ "$num_untracked" -gt 0 ] && changes=$(printf '%s%b+%s%b' "$changes" "$CYAN" "$num_untracked" "$ENDC")
    [ "$num_modified" -gt 0 ] && changes=$(printf '%s%b~%s%b' "$changes" "$YELLOWISH" "$num_modified" "$ENDC")

    git_info=$(printf ' %s%s' "$branch_display" "$changes")
fi

# =============================================================================
# Auth Warning
# =============================================================================
#
# Claude Code supports two auth methods:
#   1. OAuth (subscription) - flat monthly rate, no per-token cost
#   2. API key - per-token billing, can get expensive fast
#
# The "max" subscription is the expected state for heavy users. Any other state
# (different subscription tier, API key, or no auth) triggers a visible warning.
# This prevents accidentally burning through API credits.
#
# Credential file location is hardcoded by Claude Code.

creds_file="$HOME/.claude/.credentials.json"
auth_warning=""

if [ -f "$creds_file" ]; then
    sub_type=$(jq -r '.claudeAiOauth.subscriptionType // empty' "$creds_file" 2>/dev/null)

    if [ "$sub_type" = "max" ]; then
        # Expected state - show nothing (silent when correct)
        auth_warning=""
    elif [ -n "$sub_type" ]; then
        # Other subscription tier - might have usage limits
        auth_warning=$(printf '%b⚠ %s $%s%b' "$YELLOWISH" "$sub_type" "$cost" "$ENDC")
    elif jq -e '.apiKey' "$creds_file" >/dev/null 2>&1; then
        # API key auth - per-token billing, show cost prominently
        auth_warning=$(printf '%b⚠ API $%s%b' "$BRIGHT_RED" "$cost" "$ENDC")
    else
        auth_warning=$(printf '%b⚠ NO AUTH%b' "$BRIGHT_RED" "$ENDC")
    fi
else
    auth_warning=$(printf '%b⚠ NO AUTH%b' "$BRIGHT_RED" "$ENDC")
fi

# =============================================================================
# Context Percentage (Gradient)
# =============================================================================
#
# Visual heat map for context window usage. Color transitions:
#   Green (0-24%)     → plenty of room, no concern
#   Yellow (25-64%)   → normal usage, mild awareness
#   Orange (65-79%)   → getting full, consider wrapping up
#   Red (80-100%)     → nearly full, compaction imminent
#
# The gradient provides ambient awareness without requiring conscious monitoring.

if [ "$pct" -lt 25 ]; then
    pct_color="$CTX_GREEN"
elif [ "$pct" -lt 50 ]; then
    pct_color="$CTX_YELLOW_GREEN"
elif [ "$pct" -lt 65 ]; then
    pct_color="$CTX_YELLOW"
elif [ "$pct" -lt 80 ]; then
    pct_color="$CTX_ORANGE"
elif [ "$pct" -lt 90 ]; then
    pct_color="$CTX_RED_ORANGE"
else
    pct_color="$CTX_RED"
fi

# =============================================================================
# Output
# =============================================================================
#
# Format: DIR GIT  CONTEXT%  +ADDED -REMOVED  [WARNING]
#
# The auth warning only appears when something needs attention. This follows
# the principle of "silent when correct, loud when wrong."

printf '%s%s  %b%s%%%b  %b+%s%b %b-%s%b%s' \
    "$dir_display" "$git_info" \
    "$pct_color" "$pct" "$ENDC" \
    "$SUBTLE_GREEN" "$lines_added" "$ENDC" \
    "$SUBTLE_RED" "$lines_removed" "$ENDC" \
    "${auth_warning:+  $auth_warning}"
