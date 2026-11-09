#!/usr/bin/env bash
# Run KOReader tests in an Apple container on macOS.
#
# Usage:
#   ./scripts/test-apple-container.sh [--apply-crengine-perf-patch] [TEST_SUITE] [TEST_NAMES...]
#
# Examples:
#   ./scripts/test-apple-container.sh front readertypeset_vertical
#   ./scripts/test-apple-container.sh --apply-crengine-perf-patch front vertical_text
#
# Set APPLE_CONTAINER_NAME and APPLE_CONTAINER_VOLUME to use different resources.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(git -C "${SCRIPT_DIR}/.." rev-parse --show-toplevel)"
CONTAINER_NAME="${APPLE_CONTAINER_NAME:-kor}"
VOLUME_NAME="${APPLE_CONTAINER_VOLUME:-kor-work}"
IMAGE="${APPLE_CONTAINER_IMAGE:-koreader/kobase:6.0.0-22.04}"
CPUS="${APPLE_CONTAINER_CPUS:-8}"
MEMORY="${APPLE_CONTAINER_MEMORY:-10G}"
VOLUME_SIZE="${APPLE_CONTAINER_VOLUME_SIZE:-80G}"
APPLY_CRENGINE_PATCH=false
STARTED_CONTAINER=0
TEST_ARGS=()

usage() {
    cat <<EOF
Usage: $0 [--apply-crengine-perf-patch] [TEST_SUITE] [TEST_NAMES...]

Run KOReader tests in Apple container. Defaults to the front suite.
The container and Linux volume are kept for reuse.

Options:
  --apply-crengine-perf-patch  Apply tools/crengine-perf.patch before building
  -h, --help                   Show this help

Environment:
  APPLE_CONTAINER_NAME         Container name (default: kor)
  APPLE_CONTAINER_VOLUME       Volume name (default: kor-work)
  APPLE_CONTAINER_IMAGE        Image (default: koreader/kobase:6.0.0-22.04)
  APPLE_CONTAINER_CPUS         CPU limit (default: 8)
  APPLE_CONTAINER_MEMORY       Memory limit (default: 10G)
  APPLE_CONTAINER_VOLUME_SIZE New volume size (default: 80G)
EOF
}

for arg in "$@"; do
    case "${arg}" in
        --apply-crengine-perf-patch) APPLY_CRENGINE_PATCH=true ;;
        -h | --help)
            usage
            exit 0
            ;;
        *) TEST_ARGS+=("${arg}") ;;
    esac
done

if [[ ${#TEST_ARGS[@]} -eq 0 ]]; then
    TEST_ARGS=(front)
fi

if [[ "$(uname -s)" != Darwin ]]; then
    echo "ERROR: Apple container is available only on macOS." >&2
    exit 1
fi
if ! command -v container >/dev/null 2>&1; then
    echo "ERROR: Apple container CLI not found. Install it with: brew install container" >&2
    exit 1
fi

if ! container system status >/dev/null 2>&1; then
    container system start --enable-kernel-install
fi

if ! container volume inspect "${VOLUME_NAME}" >/dev/null 2>&1; then
    container volume create -s "${VOLUME_SIZE}" "${VOLUME_NAME}"
fi

if ! container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    container run \
        --detach \
        --name "${CONTAINER_NAME}" \
        --cpus "${CPUS}" \
        --memory "${MEMORY}" \
        --volume "${VOLUME_NAME}:/work" \
        --mount "type=bind,source=${ROOT},target=/host-src,readonly" \
        --workdir /work \
        "${IMAGE}" sleep infinity
    STARTED_CONTAINER=1
elif ! container ls --quiet | grep -Fxq "${CONTAINER_NAME}"; then
    container start "${CONTAINER_NAME}"
    STARTED_CONTAINER=1
fi

HEAD_SHA="$(git -C "${ROOT}" rev-parse HEAD)"
HEAD_SHORT="${HEAD_SHA:0:12}"
REPO_DIR="/work/koreader-${HEAD_SHORT}"
STATE_DIR="/work/.apple-container-test/${HEAD_SHORT}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/koreader-apple-test.XXXXXX")"
cleanup() {
    rm -rf "${TMP_DIR}"
    if [[ ${STARTED_CONTAINER} -eq 1 ]]; then
        container stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# The single-quoted commands below are evaluated inside the Linux container.
# shellcheck disable=SC2016
if container exec "${CONTAINER_NAME}" bash -lc \
    'test "$(git -C /work/koreader rev-parse HEAD 2>/dev/null)" = "$1"' \
    apple-container-test "${HEAD_SHA}"; then
    REPO_DIR="/work/koreader"
fi

# shellcheck disable=SC2016
if ! container exec "${CONTAINER_NAME}" bash -lc \
    'test -d "$1/.git" || { git clone --no-hardlinks /host-src "$1" && git -C "$1" submodule update --depth 1 --init --jobs 4 --recursive; }' \
    apple-container-test "${REPO_DIR}"; then
    echo "ERROR: Could not initialize the Linux worktree. Check that the container mounts this checkout at /host-src." >&2
    exit 1
fi

git -C "${ROOT}" diff --ignore-submodules=all --binary HEAD -- >"${TMP_DIR}/worktree.patch"
git -C "${ROOT}" ls-files --others --exclude-standard >"${TMP_DIR}/untracked.list"
if [[ -s "${TMP_DIR}/untracked.list" ]]; then
    (cd "${ROOT}" && COPYFILE_DISABLE=1 tar -cf "${TMP_DIR}/untracked.tar" -T "${TMP_DIR}/untracked.list")
else
    tar -cf "${TMP_DIR}/untracked.tar" -T /dev/null
fi

container copy "${TMP_DIR}/worktree.patch" "${CONTAINER_NAME}:/tmp/apple-container-worktree.patch"
container copy "${TMP_DIR}/untracked.list" "${CONTAINER_NAME}:/tmp/apple-container-untracked.list"
container copy "${TMP_DIR}/untracked.tar" "${CONTAINER_NAME}:/tmp/apple-container-untracked.tar"

# shellcheck disable=SC2016
container exec "${CONTAINER_NAME}" bash -lc '
    set -e
    repo="$1"
    state="$2"
    mkdir -p "$state"
    adopted=0

    if [ -f "$state/worktree.patch" ]; then
        if [ -s "$state/worktree.patch" ]; then
            git -C "$repo" apply --reverse "$state/worktree.patch"
        fi
    else
        git -C "$repo" diff --ignore-submodules=all --binary HEAD > /tmp/apple-container-current.patch
        if cmp -s /tmp/apple-container-current.patch /tmp/apple-container-worktree.patch; then
            cp /tmp/apple-container-current.patch "$state/worktree.patch"
            adopted=1
        elif [ -s /tmp/apple-container-current.patch ]; then
            echo "ERROR: Linux worktree has changes not synchronized by this script." >&2
            exit 1
        fi
    fi

    if [ -f "$state/untracked.list" ]; then
        while IFS= read -r path; do
            [ -n "$path" ] && rm -f -- "$repo/$path"
        done < "$state/untracked.list"
    fi

    if [ "$adopted" -eq 0 ] && [ -s /tmp/apple-container-worktree.patch ]; then
        if ! git -C "$repo" apply --check /tmp/apple-container-worktree.patch; then
            echo "ERROR: Current worktree changes do not apply to the pinned Linux checkout." >&2
            exit 1
        fi
        git -C "$repo" apply /tmp/apple-container-worktree.patch
        cp /tmp/apple-container-worktree.patch "$state/worktree.patch"
    elif [ "$adopted" -eq 0 ]; then
        : >"$state/worktree.patch"
    fi

    tar -xf /tmp/apple-container-untracked.tar -C "$repo"
    cp /tmp/apple-container-untracked.list "$state/untracked.list"
' apple-container-test "${REPO_DIR}" "${STATE_DIR}"

if [[ "${APPLY_CRENGINE_PATCH}" == true ]]; then
    # shellcheck disable=SC2016
    container exec --workdir "${REPO_DIR}" "${CONTAINER_NAME}" bash -lc '
        crengine=base/thirdparty/kpvcrlib/crengine
        patch=tools/crengine-perf.patch
        if git -C "$crengine" apply --check "$patch"; then
            git -C "$crengine" apply "$patch"
        elif ! git -C "$crengine" apply --reverse --check "$patch"; then
            echo "ERROR: crengine performance patch does not apply cleanly." >&2
            exit 1
        fi
    '
fi

container exec \
    --workdir "${REPO_DIR}" \
    --env "CCACHE_DIR=/work/ccache" \
    --env "PARALLEL_JOBS=${CPUS}" \
    "${CONTAINER_NAME}" ./kodev build

container exec \
    --workdir "${REPO_DIR}" \
    --env "CCACHE_DIR=/work/ccache" \
    --env "PARALLEL_JOBS=${CPUS}" \
    --env SDL_VIDEODRIVER=dummy \
    "${CONTAINER_NAME}" ./kodev test -d "${TEST_ARGS[@]}"
