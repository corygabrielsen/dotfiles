#!/bin/sh
# =============================================================================
# statusline.sh - Claude Code status line renderer
# =============================================================================
#
# Compatibility:
#   POSIX shell (sh, dash, ash, bash). Requires git, jq, and a terminal
#   that supports ANSI color escapes.
#
# Configuration:
#   ~/.claude/settings.json:
#     "statusLine": {
#       "type": "command",
#       "command": "~/.claude/statusline.sh"
#     }
#
# Protocol:
#   Stdin:  JSON session context emitted by Claude Code.
#   Stdout: One line of ANSI-colored text.
#
# Input fields used (others ignored):
#   .workspace.current_dir          path
#   .context_window.used_percentage 0-100
#   .cost.total_cost_usd            USD
#   .cost.total_lines_added         int
#   .cost.total_lines_removed       int
#
# Output format:
#   ~/code/project (master) +5 ~3   42%  +100 -50
#   With auth warning appended when subscription is not "max".
#
# Design:
#   - Directory and git colors mirror the user's zsh PS1 for visual
#     consistency between the shell prompt and the Claude status line.
#   - Metadata (context %, lines) uses subdued colors — informational,
#     not attention-grabbing.
#   - Context % uses a heat-map gradient (green -> red as it fills).
#   - Auth warning is silent on the "max" subscription. Any other state
#     (different tier, API key, no auth) renders prominently. Claude
#     Code can authenticate via OAuth (flat subscription) or API key
#     (per-token billing); accidental API-key use can cost hundreds of
#     dollars per session, so the warning makes the auth state visible.
#
# Install: symlinked from dotfiles/claude/statusline.sh by `make`.
# =============================================================================


# =============================================================================
# Colors
# =============================================================================
#
# ESC is pre-decoded once at script load (matches tint:61). All color
# values are pre-decoded strings; output uses plain %s. This keeps user
# data (paths, branch names) safe from accidental backslash interpretation.

ESC=$(printf '\033')

# PS1 (vibrant — mirror zsh prompt)
BLUE="${ESC}[0;34m"
LIME="${ESC}[38;5;154m"
TURQUOISE="${ESC}[38;5;45m"
ORANGE="${ESC}[38;5;166m"
MAGENTA="${ESC}[0;35m"
PURPLE="${ESC}[38;5;141m"
BRIGHT_RED="${ESC}[1;31m"
BRIGHT_GREEN="${ESC}[38;5;118m"
CYAN="${ESC}[0;36m"
YELLOWISH="${ESC}[38;5;220m"

# Subdued (informational metadata)
ENDC="${ESC}[0m"
SUBTLE_GREEN="${ESC}[38;5;108m"
SUBTLE_RED="${ESC}[38;5;131m"

# Context gradient (heat map as the window fills)
CTX_GREEN="${ESC}[38;5;108m"        # 0-24%   plenty of room
CTX_YELLOW_GREEN="${ESC}[38;5;149m" # 25-49%  comfortable
CTX_YELLOW="${ESC}[38;5;179m"       # 50-64%  getting warm
CTX_ORANGE="${ESC}[38;5;208m"       # 65-79%  caution
CTX_RED_ORANGE="${ESC}[38;5;203m"   # 80-89%  warning
CTX_RED="${ESC}[38;5;196m"          # 90-100% critical


# =============================================================================
# Formatting Helpers
# =============================================================================

# format_dir <cwd> - Set $DIR_DISPLAY to colored directory matching zsh PS1
#
# Three cases mirror parse_homedir() in .zshrc:
#   ~          when cwd == $HOME       (blue)
#   ~/<sub>    when cwd is under $HOME (lime ~ + turquoise subpath)
#   <abs>      otherwise               (orange absolute)
format_dir() {
    case "$1" in
        "$HOME")    DIR_DISPLAY="$BLUE~$ENDC" ;;
        "$HOME"/*)  DIR_DISPLAY="$LIME~$ENDC$TURQUOISE${1#"$HOME"}$ENDC" ;;
        *)          DIR_DISPLAY="$ORANGE$1$ENDC" ;;
    esac
}


# format_git <cwd> - Set $GIT_DISPLAY to ' (branch) +N +N ~N' or empty
#
# Empty when cwd is not in a git repo. Otherwise:
#   - branch:    bright-red for detached HEAD, magenta for master, purple else
#   - +N green:  staged files
#   - +N cyan:   untracked files
#   - ~N yellow: modified files (working tree)
format_git() {
    GIT_DISPLAY=""
    command git -C "$1" rev-parse --git-dir >/dev/null 2>&1 || return

    local branch branch_str
    branch=$(command git -C "$1" symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$branch" ]; then
        branch_str="$BRIGHT_RED($(command git -C "$1" rev-parse --short HEAD 2>/dev/null))$ENDC"
    elif [ "$branch" = "master" ]; then
        branch_str="$MAGENTA($branch)$ENDC"
    else
        branch_str="$PURPLE($branch)$ENDC"
    fi

    local num_staged num_untracked num_modified changes
    num_staged=$(command git -C "$1" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    num_untracked=$(command git -C "$1" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    num_modified=$(command git -C "$1" diff --name-only 2>/dev/null | wc -l | tr -d ' ')

    changes=""
    [ "$num_staged" -gt 0 ]    && changes="$changes$BRIGHT_GREEN+$num_staged$ENDC"
    [ "$num_untracked" -gt 0 ] && changes="$changes$CYAN+$num_untracked$ENDC"
    [ "$num_modified" -gt 0 ]  && changes="$changes$YELLOWISH~$num_modified$ENDC"

    GIT_DISPLAY=" $branch_str$changes"
}


# pct_color <pct> - Set $PCT_COLOR escape based on context window percentage
#
# Heat map: green for low usage, yellow/orange in the middle, red as we
# approach context exhaustion.
pct_color() {
    if   [ "$1" -lt 25 ]; then PCT_COLOR="$CTX_GREEN"
    elif [ "$1" -lt 50 ]; then PCT_COLOR="$CTX_YELLOW_GREEN"
    elif [ "$1" -lt 65 ]; then PCT_COLOR="$CTX_YELLOW"
    elif [ "$1" -lt 80 ]; then PCT_COLOR="$CTX_ORANGE"
    elif [ "$1" -lt 90 ]; then PCT_COLOR="$CTX_RED_ORANGE"
    else                       PCT_COLOR="$CTX_RED"
    fi
}


# format_auth_warning <cost> - Set $AUTH_WARNING to colored warning or empty
#
# Empty on the "max" subscription (silent when correct). Otherwise renders
# the auth state with the session cost. See the Design section above.
format_auth_warning() {
    local cost="$1"
    local creds="$HOME/.claude/.credentials.json"
    local sub_type

    if [ ! -f "$creds" ]; then
        AUTH_WARNING="$BRIGHT_RED⚠ NO AUTH$ENDC"
        return
    fi

    sub_type=$(command jq -r '.claudeAiOauth.subscriptionType // empty' "$creds" 2>/dev/null)
    if [ "$sub_type" = "max" ]; then
        AUTH_WARNING=""
    elif [ -n "$sub_type" ]; then
        AUTH_WARNING="$YELLOWISH⚠ $sub_type \$$cost$ENDC"
    elif command jq -e '.apiKey' "$creds" >/dev/null 2>&1; then
        AUTH_WARNING="$BRIGHT_RED⚠ API \$$cost$ENDC"
    else
        AUTH_WARNING="$BRIGHT_RED⚠ NO AUTH$ENDC"
    fi
}


# =============================================================================
# Main
# =============================================================================

# main - Read JSON session context from stdin, print one status line
main() {
    local input parsed cwd pct cost lines_added lines_removed
    input=$(cat)

    # One jq invocation, five fields. Each on its own line, read in order.
    parsed=$(printf '%s' "$input" | command jq -r '
        .workspace.current_dir,
        .context_window.used_percentage // 0,
        .cost.total_cost_usd // 0,
        .cost.total_lines_added // 0,
        .cost.total_lines_removed // 0
    ') || return 1

    {
        IFS= read -r cwd
        IFS= read -r pct
        IFS= read -r cost
        IFS= read -r lines_added
        IFS= read -r lines_removed
    } <<EOF
$parsed
EOF

    cost=$(printf '%.2f' "$cost")

    format_dir "$cwd"
    format_git "$cwd"
    pct_color "$pct"
    format_auth_warning "$cost"

    printf '%s%s  %s%s%%%s  %s+%s%s %s-%s%s%s' \
        "$DIR_DISPLAY" "$GIT_DISPLAY" \
        "$PCT_COLOR" "$pct" "$ENDC" \
        "$SUBTLE_GREEN" "$lines_added" "$ENDC" \
        "$SUBTLE_RED" "$lines_removed" "$ENDC" \
        "${AUTH_WARNING:+  $AUTH_WARNING}"
}

main
