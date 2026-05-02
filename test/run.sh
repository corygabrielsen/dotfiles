#!/bin/sh
# =============================================================================
# run.sh - Build and run dotfiles tests across container bases
# =============================================================================
#
# Builds one image per Dockerfile.<base> and runs test.sh inside each.
# Stops on first failure. Designed to run from anywhere (resolves repo root
# via $0); the repo root is the docker build context for all images.
#
# Usage:
#   test/run.sh                  build + test all bases (default)
#   test/run.sh ubuntu           build + test only ubuntu
#   test/run.sh --no-cache       force a fresh build (default uses cache)
#   test/run.sh --no-cache alpine
#
# Driven by: `make test-container` (which calls this with no args).
# =============================================================================

set -eu

# Repo root (one level up from this script).
REPO=$(cd "$(dirname "$0")/.." && pwd)


# =============================================================================
# Args
# =============================================================================

usage() {
    cat <<'EOF'
Usage: test/run.sh [--no-cache] [ubuntu|debian|alpine]...

Build and run dotfiles tests in containers. Defaults to all three bases.

Options:
  --no-cache    force a fresh build (default uses docker layer cache)
  -h, --help    show this help
EOF
}

# build_args is intentionally a space-delimited string and word-split below
# at the docker build call. POSIX sh has no arrays.
build_args=""
bases=""
for arg in "$@"; do
    case "$arg" in
        --no-cache)            build_args="$build_args --no-cache" ;;
        ubuntu|debian|alpine)  bases="$bases $arg" ;;
        -h|--help)             usage; exit 0 ;;
        *)
            printf 'unknown arg: %s\n' "$arg" >&2
            printf 'see: %s --help\n' "$0" >&2
            exit 2 ;;
    esac
done
[ -n "$bases" ] || bases="ubuntu debian alpine"


# =============================================================================
# Output helpers
# =============================================================================

if [ -t 1 ]; then
    ESC=$(printf '\033')
    BOLD="${ESC}[1m"; CYAN="${ESC}[0;36m"; ENDC="${ESC}[0m"
else
    BOLD=""; CYAN=""; ENDC=""
fi


# =============================================================================
# Run
# =============================================================================

command -v docker >/dev/null 2>&1 || {
    printf 'docker not found on PATH\n' >&2
    exit 1
}

cd "$REPO"

for base in $bases; do
    dockerfile="test/Dockerfile.$base"
    [ -f "$dockerfile" ] || { printf 'no such Dockerfile: %s\n' "$dockerfile" >&2; exit 1; }

    printf '\n%s================================================================%s\n' \
        "$CYAN" "$ENDC"
    printf '%sTesting on %s%s\n' "$BOLD" "$base" "$ENDC"
    printf '%s================================================================%s\n' \
        "$CYAN" "$ENDC"

    # shellcheck disable=SC2086  # build_args intentionally word-split
    docker build $build_args -f "$dockerfile" -t "dotfiles-test:$base" .
    docker run --rm "dotfiles-test:$base"
done

printf '\n%sall bases passed%s\n' "$BOLD" "$ENDC"
