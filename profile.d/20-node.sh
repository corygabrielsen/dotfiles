# shellcheck shell=sh
# =============================================================================
# 20-node.sh - node.js / nvm PATH
# =============================================================================
#
# Adds nvm's default node version to PATH without sourcing nvm.sh.
# Reads $NVM_DIR/alias/default; "node" or empty = highest installed.
# Full nvm command is loaded by ~/.zshrc for interactive use.
#
# `sort -V` (semver-aware) is GNU-only; BSD sort (macOS) lacks it. When
# unsupported we fall back to a sed+sort-by-numeric-keys pipeline: extract
# the major/minor/patch numbers, sort by each numerically, then strip the
# prefix. Lexical sort (the obvious fallback) is wrong — it picks v9.x.x
# over v20.x.x. POSIX sort + sed -E both handle the fallback portably.
# =============================================================================

# `:-` so an inherited NVM_DIR (e.g., from direnv on a project that
# pins a per-repo nvm tree) wins over the default.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -d "$NVM_DIR/versions/node" ]; then
    _nvm_ver=""
    [ -r "$NVM_DIR/alias/default" ] \
        && IFS= read -r _nvm_ver < "$NVM_DIR/alias/default"

    # Empty glob matches all versions; non-empty pins to a specific one.
    _nvm_glob=""
    [ -n "$_nvm_ver" ] && [ "$_nvm_ver" != "node" ] && _nvm_glob="$_nvm_ver"

    # Enumerate version dirs via ls + case filter rather than shell glob.
    # zsh's NOMATCH option would raise an error on `v*/bin` when no version
    # is installed (fresh nvm, deleted versions, etc.); ls returns empty
    # output silently. Newline-separated to feed the sort pipeline below.
    _nvm_versions=""
    for _v in $(command ls "$NVM_DIR/versions/node" 2>/dev/null); do
        case "$_v" in
            v"$_nvm_glob"*)
                _nvm_versions="${_nvm_versions}${_nvm_versions:+
}$NVM_DIR/versions/node/$_v/bin"
                ;;
        esac
    done

    # Probe sort -V once; can't store the command in a variable because zsh
    # doesn't word-split unquoted expansions (it would look for a command
    # literally named "sort -V"). `command` prefix on each external tool
    # defeats interactive aliases that would corrupt the sort.
    _nvm_bin=""
    if [ -n "$_nvm_versions" ]; then
        if echo | command sort -V >/dev/null 2>&1; then
            _nvm_bin=$(printf '%s' "$_nvm_versions" | command sort -V | command tail -1)
        else
            # BSD sort: parse vMAJOR.MINOR.PATCH out of the path, sort by
            # each field numerically, then strip the prefix. Pre-release
            # suffixes like v22.0.0-rc1 are not handled (rare for defaults).
            _nvm_bin=$(printf '%s' "$_nvm_versions" \
                | command sed -E 's|.*/v([0-9]+)\.([0-9]+)\.([0-9]+)/.*|\1 \2 \3 &|' \
                | command sort -k1,1n -k2,2n -k3,3n \
                | command tail -1 \
                | command sed -E 's|^[0-9]+ [0-9]+ [0-9]+ ||')
        fi
    fi

    [ -n "$_nvm_bin" ] && PATH="$_nvm_bin:$PATH"
    unset _nvm_ver _nvm_glob _nvm_versions _nvm_bin _v
fi
