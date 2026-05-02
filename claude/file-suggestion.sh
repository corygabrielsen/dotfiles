#!/bin/sh
# =============================================================================
# file-suggestion.sh - Polyrepo-aware file suggestions for Claude Code
# =============================================================================
#
# Compatibility:
#   POSIX shell (sh, dash, ash, bash). Uses `local` — de facto standard in
#   modern shells; planned for the next POSIX revision. Requires git, jq,
#   awk, sed, sort, cut, head.
#
# Configuration:
#   ~/.claude/settings.json:
#     "fileSuggestion": {
#       "type": "command",
#       "command": "~/.claude/file-suggestion.sh"
#     }
#
#   Optional ~/.claude/file-suggestion.local.sh for per-machine overrides:
#     export CLAUDE_WORKSPACE_MARKER="my-marker.json"
#
# Protocol:
#   Stdin:  JSON with a "query" field, e.g., {"query": "README"}
#   Stdout: Newline-separated file paths (up to 20)
#
# Problem:
#   Polyrepo workspaces clone repos as gitignored subdirectories. Claude
#   Code's default @ autocomplete respects .gitignore, making subrepos
#   invisible. You type @README and only see the workspace README, not
#   the README in each cloned subrepo.
#
# Solution:
#   1. Walk up looking for a marker file to find the workspace root.
#   2. Collect tracked + visible-untracked files from the workspace and
#      from every gitignored sibling repo (in parallel).
#   3. Rewrite paths to be relative to the current working directory.
#   4. Filter by query and prioritize: local files first, then siblings
#      sorted by depth, then alphabetical.
#
# Example:
#   $ printf '{"query":"README"}' | file-suggestion.sh
#   README.md
#   ../protocol/README.md
#   ../explorer/README.md
#
# Design notes:
#   - Walk up for a marker?    Identifies the workspace root so we can reach
#                              sibling repos. Configurable via env var.
#   - Why parallel?            Workspaces may have 10+ subrepos; sequential
#                              git ls-files would add visible latency.
#   - Why local-first?         In protocol/, @src usually means
#                              protocol/src/*, not explorer/src/*.
#   - Why depth-sort siblings? Closer files (../foo) are more likely
#                              targets than distant ones (../../bar).
#
# Install: symlinked from dotfiles/claude/file-suggestion.sh by `make`.
# =============================================================================

# =============================================================================
# Configuration
# =============================================================================

# Source per-machine overrides before declaring readonly defaults.
# shellcheck source=/dev/null
[ -f ~/.claude/file-suggestion.local.sh ] && . ~/.claude/file-suggestion.local.sh

readonly MAX_RESULTS=20
readonly WORKSPACE_MARKER="${CLAUDE_WORKSPACE_MARKER:-.workspace}"

# =============================================================================
# Workspace Detection
# =============================================================================

# find_workspace_root - Locate workspace root by walking up from $PWD
#
# Stdout: Path to directory containing $WORKSPACE_MARKER, or $PWD if none
#         is found.
#
# The fallback to $PWD provides graceful degradation: non-polyrepo projects
# still get file suggestions, just without cross-repo reach.
find_workspace_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/$WORKSPACE_MARKER" ]; then
            printf '%s' "$dir"
            return
        fi
        dir="${dir%/*}"
        dir="${dir:-/}"
    done
    printf '%s' "$PWD"
}

# =============================================================================
# File Collection
# =============================================================================

# collect_all_files - Gather files from workspace and every subrepo
#
# Stdout: One path per line, relative to the workspace root. Output may
#         interleave from parallel jobs; downstream sorting fixes order.
#
# Workspace files come from `git ls-files --cached --others --exclude-standard`
# (tracked + untracked-visible; disjoint sets, union is what we want).
#
# Subrepos are gitignored directories containing a .git/ entry. Each is
# queried in a backgrounded subshell. The heredoc keeps the loop in the
# main shell so variables stay in scope — POSIX has no process substitution.
collect_all_files() {
    command git ls-files --cached --others --exclude-standard 2>/dev/null \
        || true

    local dir
    while IFS= read -r dir; do
        [ -d "$dir/.git" ] || continue
        (
            command git -C "$dir" ls-files --cached --others --exclude-standard 2>/dev/null \
                | command sed "s|^|$dir/|"
        ) &
    done <<EOF
$(command git ls-files --others --ignored --exclude-standard --directory 2>/dev/null \
    | command sed 's|/$||')
EOF
    wait
}

# =============================================================================
# Path Transformation
# =============================================================================

# transform_to_relative <subdir> - Rewrite paths relative to current dir
#
# $1 is the subdirectory of the workspace where we currently are; empty
# means we're at the workspace root and paths pass through unchanged.
#
# Stdin:  One workspace-relative path per line.
# Stdout: One path per line, or "." if a path is the subdir itself.
#
# Example: subdir=protocol, line=protocol/src/main.rs -> src/main.rs
#          subdir=protocol, line=explorer/src/lib.rs  -> ../explorer/src/lib.rs
transform_to_relative() {
    local subdir="$1"

    if [ -z "$subdir" ]; then
        cat
        return
    fi

    command awk -v subdir="$subdir" '
    BEGIN { subdir_depth = split(subdir, subdir_parts, "/") }
    length > 0 {
        file_depth = split($0, file_parts, "/")

        # Find the longest matching prefix.
        common_depth = 0
        for (i = 1; i <= subdir_depth && i <= file_depth; i++) {
            if (subdir_parts[i] != file_parts[i]) break
            common_depth = i
        }

        result = ""

        # Climb out of subdir to the common ancestor.
        for (i = 1; i <= subdir_depth - common_depth; i++) result = result "../"

        # Descend from the common ancestor to the file.
        for (i = common_depth + 1; i <= file_depth; i++) {
            if (i > common_depth + 1) result = result "/"
            result = result file_parts[i]
        }

        print (result != "" ? result : ".")
    }'
}

# =============================================================================
# Filtering and Ranking
# =============================================================================

# filter_and_prioritize <query> - Match query and sort by relevance
#
# $1 is the query string (case-insensitive substring match).
#
# Stdin:  One path per line.
# Stdout: Up to $MAX_RESULTS matching paths, one per line, sorted by relevance.
#
# Ranking (Schwartzian transform — tag, sort, untag):
#   1. Local files first (no `../` prefix).
#   2. Among siblings, files at lower depth first.
#   3. Alphabetical tiebreaker.
filter_and_prioritize() {
    local query="$1"

    command awk -v query="$query" '
    BEGIN { ql = tolower(query) }
    {
        if (index(tolower($0), ql) == 0) next
        is_sibling = (substr($0, 1, 2) == "..")
        depth = is_sibling ? split($0, _, "/") : 0
        printf "%d %05d %s\n", is_sibling, depth, $0
    }' \
    | LC_ALL=C command sort -t' ' -k1,1n -k2,2n -k3 \
    | command cut -d' ' -f3- \
    | command head -n "$MAX_RESULTS"
}

# =============================================================================
# Main
# =============================================================================

# main - Read query JSON from stdin, emit matching file paths on stdout.
#
# Returns: 0 on success, 1 if jq fails to parse the input or `cd` fails.
main() {
    local query root subdir
    query=$(command jq -r '.query') || return 1

    root=$(find_workspace_root)
    subdir="${PWD#"$root"}"
    subdir="${subdir#/}"

    cd "$root" || return 1
    collect_all_files \
        | transform_to_relative "$subdir" \
        | filter_and_prioritize "$query"
}

main
