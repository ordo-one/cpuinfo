#!/usr/bin/env bash
# ===----------------------------------------------------------------------===//
#
# Copyright © 2022-2026 Ordo One AB
#
# Licensed under Apache License v2.0
# See LICENSE.txt for license information
#
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2022-2026 Ordo One AB
#
# https://ordo.one
#
# ===----------------------------------------------------------------------===//

# Scripts/update-cpuinfo.sh
#
# Updates the vendored cpuinfo sources to the latest upstream commit.
# After running, review the diffs, verify shim files match, then open a PR.
#
# Usage:
#   ./Scripts/update-cpuinfo.sh                # update to latest main
#   ./Scripts/update-cpuinfo.sh <SHA>          # pin to a specific commit (full 40-character SHA)
#   ./Scripts/update-cpuinfo.sh <branch>       # pin to a branch tip
#   ./Scripts/update-cpuinfo.sh <tag>          # pin to a tag

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM_URL="https://github.com/pytorch/cpuinfo.git"
VENDOR_DST="$REPO_ROOT/Sources/_cpuinfo"
VERSION_FILE="$REPO_ROOT/CPUINFO_VERSION"
SWIFT_VERSION_FILE="$REPO_ROOT/Sources/CpuInfo/CpuInfo.swift"
NOTICES_FILE="$REPO_ROOT/NOTICES"
WORK_DIR="$(mktemp -d)"
STAGING_DIR="$WORK_DIR/staging"
TARGET_REF="${1:-main}"
OLD_VENDOR="$WORK_DIR/vendor_old"
SWAP_COMMITTED=false
META_BACKUP="$WORK_DIR/meta"

# Known platform directories we include from src/.
# If upstream adds new ones, the script warns you.
KNOWN_INCLUDED_DIRS=(cpuinfo x86 arm linux mach)
# Excluded at any depth, so src/x86/windows, src/arm/android etc. are skipped too.
KNOWN_EXCLUDED_DIRS=(riscv powerpc windows freebsd android emscripten mock)

# Until the swap and metadata updates finish, put the previous vendor tree and metadata back on any exit.
cleanup() {
    if ! $SWAP_COMMITTED && [[ -d "$OLD_VENDOR" ]]; then
        rm -rf "$VENDOR_DST"
        mv "$OLD_VENDOR" "$VENDOR_DST"
        echo "==> Restored previous Sources/_cpuinfo." >&2
    fi
    if ! $SWAP_COMMITTED && [[ -d "$META_BACKUP" ]]; then
        cp -p "$META_BACKUP/CPUINFO_VERSION" "$VERSION_FILE" 2>/dev/null || true
        cp -p "$META_BACKUP/NOTICES" "$NOTICES_FILE" 2>/dev/null || true
        cp -p "$META_BACKUP/CpuInfo.swift" "$SWIFT_VERSION_FILE" 2>/dev/null || true
        echo "==> Restored previous version metadata." >&2
    fi
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# ── Clone upstream ────────────────────────────────────────────────────────────

echo "==> Cloning cpuinfo ..."

if [[ "$TARGET_REF" =~ ^[0-9a-f]{7,39}$ ]]; then
    # A shallow fetch can't resolve an abbreviated SHA, so only a branch or tag with a hex name goes on.
    # ls-remote exits 2 when no ref matches; anything else non-zero means it couldn't ask.
    ls_status=0
    git ls-remote --exit-code --heads --tags "$UPSTREAM_URL" "$TARGET_REF" >/dev/null 2>"$WORK_DIR/ls_err" || ls_status=$?
    if [[ $ls_status -eq 2 ]]; then
        echo "ERROR: '$TARGET_REF' looks like a short SHA; pass the full 40-character commit SHA." >&2
        exit 1
    elif [[ $ls_status -ne 0 ]]; then
        echo "ERROR: Could not list upstream refs to check '$TARGET_REF':" >&2
        cat "$WORK_DIR/ls_err" >&2
        exit 1
    fi
fi

if [[ "$TARGET_REF" =~ ^[0-9a-f]{40}$ ]]; then
    # A full commit SHA — clone default branch, then fetch it.
    git clone --quiet --depth=1 "$UPSTREAM_URL" "$WORK_DIR/cpuinfo"
    echo "==> Fetching commit $TARGET_REF ..."
    git -C "$WORK_DIR/cpuinfo" fetch --quiet --depth=1 origin "$TARGET_REF"
    git -C "$WORK_DIR/cpuinfo" checkout --quiet FETCH_HEAD
else
    # Branch name or tag — clone it directly.
    if ! git clone --quiet --depth=1 --branch "$TARGET_REF" "$UPSTREAM_URL" "$WORK_DIR/cpuinfo" 2>"$WORK_DIR/clone_err"; then
        echo "ERROR: Failed to clone branch/tag '$TARGET_REF'." >&2
        cat "$WORK_DIR/clone_err" >&2
        exit 1
    fi
fi

NEW_SHA=$(git -C "$WORK_DIR/cpuinfo" rev-parse HEAD)
OLD_SHA=$(cat "$VERSION_FILE" 2>/dev/null || echo "(none)")

echo "==> Resolved $TARGET_REF -> $NEW_SHA"

# ── Early exit if already up to date ──────────────────────────────────────────

if [[ "$NEW_SHA" == "$OLD_SHA" ]]; then
    echo "==> Already up to date at $NEW_SHA. Nothing to do."
    exit 0
fi

echo "==> Updating $OLD_SHA -> $NEW_SHA"
SRC="$WORK_DIR/cpuinfo"

# ── Diff build files before touching anything ─────────────────────────────────
# Fetch the old commit into the shallow clone so we can diff build files.

if [[ "$OLD_SHA" != "(none)" ]]; then
    echo "==> Fetching previous commit $OLD_SHA for build-file diff ..."
    if git -C "$SRC" fetch --quiet --depth=1 origin "$OLD_SHA" 2>/dev/null; then
        echo ""
        echo "================================================================"
        echo "  CMakeLists.txt + configure.py diff — review before merging!"
        echo "================================================================"
        for BUILD_FILE in CMakeLists.txt configure.py; do
            PREV="$WORK_DIR/prev_${BUILD_FILE}"
            if git -C "$SRC" show "${OLD_SHA}:${BUILD_FILE}" > "$PREV" 2>/dev/null; then
                echo ""
                echo "--- $BUILD_FILE ---"
                diff --unified=3 "$PREV" "$SRC/$BUILD_FILE" || true
            else
                echo "(No previous $BUILD_FILE to diff against)"
            fi
        done
        echo ""
        echo "If source file lists changed, update the shim files in Sources/_cpuinfo/shims/ to match."
        echo ""
    else
        echo "WARNING: Could not fetch old commit $OLD_SHA — skipping build-file diff." >&2
        echo "         Review CMakeLists.txt and configure.py manually." >&2
    fi
fi

# ── Warn about new upstream src/ subdirectories ──────────────────────────────

ALL_KNOWN=("${KNOWN_INCLUDED_DIRS[@]}" "${KNOWN_EXCLUDED_DIRS[@]}")
while IFS= read -r dir_name; do
    found=false
    for known in "${ALL_KNOWN[@]}"; do
        if [[ "$dir_name" == "$known" ]]; then
            found=true
            break
        fi
    done
    if ! $found; then
        echo "WARNING: New upstream directory src/$dir_name/ is not in the include or exclude list." >&2
        echo "         Update KNOWN_INCLUDED_DIRS or KNOWN_EXCLUDED_DIRS in this script." >&2
    fi
done < <(find "$SRC/src" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

# ── Stage all vendored files into a temp copy ─────────────────────────────────
# We build the new tree in STAGING_DIR so that the live repo is untouched
# until everything succeeds.

echo "==> Staging vendored sources ..."
mkdir -p "$STAGING_DIR"

# Copy the entire current vendor tree as a base (preserves shims/, etc.)
rsync -a "$VENDOR_DST/" "$STAGING_DIR/"

# Overwrite the upstream-tracked directories into the staging copy.
# Using rsync --delete (without rm -rf first) so unchanged files keep their
# timestamps, giving cleaner git diffs.

sync_dir() {
    local rel="$1"
    echo "  Syncing $rel ..."
    mkdir -p "$STAGING_DIR/$rel"
    rsync -a --delete "$SRC/$rel/" "$STAGING_DIR/$rel/"
}

# include/ needs special handling: preserve our custom headers and module map.
echo "  Syncing include ..."
mkdir -p "$STAGING_DIR/include"
rsync -a --delete \
    --exclude="cpuinfo_affinity.h" \
    --exclude="cpuinfo_x86_freq.h" \
    --exclude="module.modulemap" \
    "$SRC/include/" "$STAGING_DIR/include/"

sync_dir "deps/clog/include"

echo "  Syncing deps/clog/src/clog.c ..."
mkdir -p "$STAGING_DIR/deps/clog/src"
cp "$SRC/deps/clog/src/clog.c" "$STAGING_DIR/deps/clog/src/clog.c"

# BSD-2 requires keeping both notices; a change to either must be mirrored in NOTICES.
echo "  Syncing LICENSE files ..."
cp "$SRC/LICENSE" "$STAGING_DIR/LICENSE"
cp "$SRC/deps/clog/LICENSE" "$STAGING_DIR/deps/clog/LICENSE"

# src — selective: common top-level .c/.h, plus specific platform directories.
echo "  Syncing src (selective) ..."

# Build rsync filter args dynamically from the known lists. --delete-excluded
# drops excluded dirs carried over from the previous vendor tree.
RSYNC_ARGS=(rsync -a --delete --delete-excluded)
for dir in "${KNOWN_EXCLUDED_DIRS[@]}"; do
    RSYNC_ARGS+=(--exclude="$dir/")
done
# Include source files and known platform directories.
RSYNC_ARGS+=(--include="*.c" --include="*.h")
for dir in "${KNOWN_INCLUDED_DIRS[@]}"; do
    RSYNC_ARGS+=(--include="$dir/" --include="$dir/**")
done
# Exclude everything else (files and directories).
RSYNC_ARGS+=(--exclude="*")
RSYNC_ARGS+=("$SRC/src/" "$STAGING_DIR/src/")

"${RSYNC_ARGS[@]}"

# Note: shims/ directory is NOT touched — it contains our wrapper files.
# If the upstream source file lists changed, the shims must be updated manually.

# ── Atomic swap: staging -> live ──────────────────────────────────────────────
# Move current vendor dir aside, move staging in, then remove old.
# This minimises the window where the repo is in an inconsistent state.

echo "==> Swapping vendored sources into place ..."
mv "$VENDOR_DST" "$OLD_VENDOR"
mv "$STAGING_DIR" "$VENDOR_DST"

# ── Build check (before updating version file) ───────────────────────────────

echo "==> Running swift build ..."
if ! swift build --package-path "$REPO_ROOT"; then
    echo "" >&2
    echo "ERROR: swift build failed. Rolling back vendored sources." >&2
    # Roll back: restore old vendor dir, leave repo clean.
    rm -rf "$VENDOR_DST"
    mv "$OLD_VENDOR" "$VENDOR_DST"
    echo "==> Rollback complete. Sources/_cpuinfo is unchanged." >&2
    exit 1
fi

# ── Update version files (only after successful build) ───────────────────────

mkdir -p "$META_BACKUP"
cp -p "$VERSION_FILE" "$NOTICES_FILE" "$META_BACKUP"/ 2>/dev/null || true
cp -p "$SWIFT_VERSION_FILE" "$META_BACKUP/CpuInfo.swift"
echo "$NEW_SHA" > "$VERSION_FILE"
echo "==> CPUINFO_VERSION updated to $NEW_SHA"

# Keep the Swift constant in sync with CPUINFO_VERSION so that the commit is
# readable at runtime via CpuInfoVersion.vendoredCpuinfoCommit.
if [[ -f "$SWIFT_VERSION_FILE" ]]; then
    # BSD sed on macOS requires the '' argument to -i; GNU sed does not accept it.
    if sed --version >/dev/null 2>&1; then
        sed -i "s|\(vendoredCpuinfoCommit = \"\)[0-9a-f]\{40\}\(\"\)|\1${NEW_SHA}\2|" "$SWIFT_VERSION_FILE"
    else
        sed -i '' "s|\(vendoredCpuinfoCommit = \"\)[0-9a-f]\{40\}\(\"\)|\1${NEW_SHA}\2|" "$SWIFT_VERSION_FILE"
    fi
    echo "==> CpuInfoVersion.vendoredCpuinfoCommit updated to $NEW_SHA"
fi

# Keep NOTICES in sync with CPUINFO_VERSION.
if [[ -f "$NOTICES_FILE" ]]; then
    if sed --version >/dev/null 2>&1; then
        sed -i "s|^Vendored commit: [0-9a-f]\{40\}|Vendored commit: ${NEW_SHA}|" "$NOTICES_FILE"
    else
        sed -i '' "s|^Vendored commit: [0-9a-f]\{40\}|Vendored commit: ${NEW_SHA}|" "$NOTICES_FILE"
    fi
    echo "==> NOTICES updated to $NEW_SHA"
fi

SWAP_COMMITTED=true

# ── Summary of changed files ─────────────────────────────────────────────────

echo ""
echo "==> Files changed in Sources/_cpuinfo (M modified, ?? added, D deleted):"
git -C "$REPO_ROOT" status --porcelain --untracked-files=all -- Sources/_cpuinfo/ 2>/dev/null || true
echo ""

echo "Done. Next steps:"
echo "    1. Review the CMakeLists.txt and configure.py diffs above."
echo "       If source file lists changed, update shim files in Sources/_cpuinfo/shims/."
echo "       If a LICENSE file changed, update NOTICES to match."
echo "    2. swift test"
echo "    3. container run --rm -v \"\$(pwd)\":/pkg -w /pkg swift:6.2 swift test"
echo "    4. Open a PR with branch: vendor/cpuinfo-${NEW_SHA:0:12}"
