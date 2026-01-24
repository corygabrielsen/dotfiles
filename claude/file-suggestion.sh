#!/bin/bash
# =============================================================================
# Polyrepo-Aware File Suggestion for Claude Code
# =============================================================================
#
# PROBLEM
#   Polyrepo workspaces clone repos as gitignored subdirectories. Claude Code's
#   default @ autocomplete respects .gitignore, making subrepos invisible to
#   file suggestions. You type @README and only see the workspace README, not
#   the README in each cloned subrepo.
#
# SOLUTION
#   1. Find workspace root by walking up looking for a marker file
#   2. Collect files from workspace AND all subrepo git indexes (in parallel)
#   3. Transform paths to be relative to current working directory
#   4. Prioritize: local files first, then siblings sorted by depth
#
# CONFIGURATION
#   ~/.claude/settings.json:
#   {
#     "fileSuggestion": {
#       "type": "command",
#       "command": "~/.claude/file-suggestion.sh"
#     }
#   }
#
#   Optional: ~/.claude/file-suggestion.local.sh for work-specific overrides:
#     export CLAUDE_WORKSPACE_MARKER="my-marker.json"
#
# PROTOCOL
#   Input:  JSON on stdin with "query" field, e.g., {"query": "README"}
#   Output: Newline-separated file paths on stdout (max 20)
#
# EXAMPLE
#   Input:  {"query": "README"}
#   Output:
#     README.md
#     ../protocol/README.md
#     ../explorer/README.md
#
# DESIGN DECISIONS
#
#   Why walk up for a marker file?
#     The marker identifies the workspace root. Without it, we'd only search
#     the current git repo, missing sibling subrepos. The marker is configurable
#     so different projects can use different conventions.
#
#   Why parallel subrepo queries?
#     Large workspaces may have 10+ subrepos. Sequential git ls-files calls
#     would add noticeable latency. Backgrounding each query and waiting for
#     all to complete keeps autocomplete responsive.
#
#   Why prioritize local files?
#     When you're in protocol/ and type @src, you probably want protocol/src/*
#     before explorer/src/*. Local-first matches user intent.
#
#   Why sort siblings by depth?
#     Closer files (fewer ../) are more likely targets. ../foo is more relevant
#     than ../../bar in most navigation patterns.
#
# =============================================================================

set -o errexit
set -o nounset
set -o pipefail

# =============================================================================
# Configuration
# =============================================================================
#
# Source local overrides before setting readonly variables. This allows
# work-specific configuration without modifying this versioned file.
#
# Example ~/.claude/file-suggestion.local.sh:
#   export CLAUDE_WORKSPACE_MARKER="repos.json"

# shellcheck source=/dev/null
[[ -f ~/.claude/file-suggestion.local.sh ]] && source ~/.claude/file-suggestion.local.sh

readonly MAX_RESULTS=20
readonly WORKSPACE_MARKER="${CLAUDE_WORKSPACE_MARKER:-.workspace}"

# =============================================================================
# Workspace Detection
# =============================================================================

# find_workspace_root - Walk up directory tree looking for marker file
#
# Returns the directory containing $WORKSPACE_MARKER, or PWD if not found.
# The fallback to PWD provides graceful degradation for non-polyrepo projects:
# single-repo projects still get file suggestions, just without cross-repo reach.
#
find_workspace_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/$WORKSPACE_MARKER" ]]; then
            printf '%s' "$dir"
            return
        fi
        dir="${dir%/*}"  # Strip last path component (pure bash, no subshell)
        dir="${dir:-/}"  # Handle root case: empty string becomes "/"
    done
    printf '%s' "$PWD"
}

# =============================================================================
# File Collection
# =============================================================================

# collect_all_files - Gather files from workspace and all subrepos
#
# Uses git ls-files to get tracked and untracked (but not ignored) files.
# Subrepos are identified as gitignored directories containing .git/.
# Each subrepo is queried in parallel for performance.
#
# Output: One file path per line, relative to workspace root
#
collect_all_files() {
    # Workspace files: tracked + untracked (non-ignored)
    #
    # Git flags explained:
    #   --cached = files in git index (tracked)
    #   --others = files NOT in git index (untracked)
    #   --exclude-standard = apply .gitignore rules (only affects --others)
    #
    # These are disjoint sets; combining them gives tracked ∪ untracked-visible.
    # The "|| true" prevents errexit from killing script if not in a git repo.
    git ls-files --cached --others --exclude-standard 2>/dev/null || true

    # Subrepos: gitignored directories that are themselves git repos
    #
    # Parallelism pattern:
    #   - Process substitution "< <(...)" keeps while loop in main shell
    #   - Background jobs "{ ... } &" parallelize subrepo queries
    #   - "wait" blocks until all background jobs complete
    #   - Output may interleave, but we sort later so order doesn't matter
    #
    local dir
    while IFS= read -r dir; do
        if [[ -d "$dir/.git" ]]; then
            git -C "$dir" ls-files --cached --others --exclude-standard 2>/dev/null \
                | sed "s|^|$dir/|" &
        fi
    done < <(
        # Find gitignored directories (potential subrepos)
        #   --others --ignored = untracked AND ignored (in .gitignore)
        #   --directory = list directories themselves, not contents
        git ls-files --others --ignored --exclude-standard --directory 2>/dev/null \
            | sed 's|/$||'
    )
    wait
}

# =============================================================================
# Path Transformation
# =============================================================================

# transform_to_relative - Convert workspace-relative paths to PWD-relative
#
# When working in a subdirectory, file paths need adjustment:
#   workspace/protocol/src/main.rs → ../protocol/src/main.rs (if in explorer/)
#
# Args:
#   $1 - Current subdirectory relative to workspace (empty if at root)
#
# Algorithm:
#   1. Split both paths into components
#   2. Find longest common prefix
#   3. Add "../" for each component we need to go up
#   4. Append remaining path components
#
transform_to_relative() {
    local subdir="$1"

    # At workspace root: paths are already correct
    if [[ -z "$subdir" ]]; then
        cat
        return
    fi

    # Example: subdir="a/b/c", file="a/b/x/y.rs"
    #   common prefix = "a/b" (2 components)
    #   go up 1 level (from c) = "../"
    #   append "x/y.rs"
    #   result = "../x/y.rs"
    #
    awk -v subdir="$subdir" '
    BEGIN {
        subdir_depth = split(subdir, subdir_parts, "/")
    }
    length > 0 {
        file_depth = split($0, file_parts, "/")

        # Count matching components from the start
        common_depth = 0
        for (i = 1; i <= subdir_depth && i <= file_depth; i++) {
            if (subdir_parts[i] != file_parts[i]) break
            common_depth = i
        }

        result = ""

        # Step 1: go up from subdir to common ancestor
        levels_up = subdir_depth - common_depth
        for (i = 1; i <= levels_up; i++) {
            result = result "../"
        }

        # Step 2: go down from common ancestor to file
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

# filter_and_prioritize - Match query and sort by relevance
#
# Ranking strategy:
#   1. Local files first (no ../ prefix) - you're probably looking here
#   2. Among siblings, closer files first (fewer path components)
#   3. Alphabetical tiebreaker for stability
#
# Implementation uses a Schwartzian transform:
#   1. Tag each line with sort keys
#   2. Sort by keys
#   3. Strip keys from output
#
filter_and_prioritize() {
    local query="$1"

    awk -v query="$query" '
    BEGIN {
        query_lower = tolower(query)
    }
    {
        # Case-insensitive substring match
        if (index(tolower($0), query_lower) == 0) next

        is_sibling = (substr($0, 1, 2) == "..") ? 1 : 0
        depth = is_sibling ? split($0, _, "/") : 0

        # Output: IS_SIBLING DEPTH PATH (for sorting)
        printf "%d %05d %s\n", is_sibling, depth, $0
    }' \
    | LC_ALL=C sort -t' ' -k1,1n -k2,2n -k3 \
    | cut -d' ' -f3- \
    | head -n "$MAX_RESULTS"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local query root subdir

    # Parse JSON input from Claude Code
    query="$(jq -r '.query')"

    # Locate workspace and compute position within it
    root="$(find_workspace_root)"
    subdir="${PWD#"$root"}"
    subdir="${subdir#/}"

    # Run pipeline from workspace root
    cd "$root"
    collect_all_files \
        | transform_to_relative "$subdir" \
        | filter_and_prioritize "$query"
}

main
