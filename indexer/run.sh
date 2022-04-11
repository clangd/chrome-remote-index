#!/bin/bash
#===-- run.sh -------------------------------------------------------------===//
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===-----------------------------------------------------------------------===//
#
# Produce Chromium index.
#
#===-----------------------------------------------------------------------===//

set -eux

cd /

# Prepare the environment: download all necessary binaries and fetch the source
# code.

export CLANGD_INDEXER=$(find clangd_binaries -name "clangd-indexer" | xargs readlink -f)

export PATH="$PATH:$(readlink -f depot_tools)"

# Update Chromium sources.
cd chromium/src
# Reset changes in package installation scripts.
git reset --hard
git checkout main
git pull
gclient fetch
gclient sync --delete_unversioned_trees
gclient runhooks

mkdir -p out/Default
export BUILD_DIR=$(readlink -f out/Default)


# Create a release, will be empty for now and incrementally populated
# throughout the indexing pipeline.

DATE=$(date -u +%Y%m%d)
COMMIT=$(git rev-parse --short HEAD)
RELEASE_NAME="index/${DATE}"
gh release create $RELEASE_NAME --repo clangd/chrome-remote-index \
  --title="Index at $DATE" \
  --notes="Chromium index artifacts at $COMMIT with project root \`$PWD\`."

# The indexing pipeline is common. Each platform will only have to do the
# preparation step (set up the build configuration and install dependencies).

# $1: Platform name.
# $2: GN arguments for the chosen platform.
# TODO: Add logging for failures.
index() {
  PLATFORM=$1

  GN_ARGS=$2

  echo "Indexing for $PLATFORM"

  gn gen --args="$GN_ARGS" $BUILD_DIR

  # Build generated files.
  ninja -C $BUILD_DIR -t targets all | grep -i '^gen/' | grep -E "\.(cpp|h|inc|cc)\:" | cut -d':' -f1 | xargs autoninja -C $BUILD_DIR

  # Get compile_commands.json for clangd-indexer.
  tools/clang/scripts/generate_compdb.py -p $BUILD_DIR > compile_commands.json

  $CLANGD_INDEXER --executor=all-TUs compile_commands.json > /chrome-$PLATFORM.idx

  7z a chrome-index-$PLATFORM-$DATE.zip /chrome-$PLATFORM.idx

  gh release upload --repo clangd/chrome-remote-index $RELEASE_NAME chrome-index-$PLATFORM-$DATE.zip

  # Clean up the artifacts.
  rm -rf $BUILD_DIR /chrome-$PLATFORM.idx chrome-index-$PLATFORM-$DATE.zip
}

# --- Linux ---

# Remove snapcraft from dependency list: installing it is not feasible inside
# Docker.
sed -i '/if package_exists snapcraft/,/fi/d' ./build/install-build-deps.sh
./build/install-build-deps.sh

index linux 'target_os="linux"' || true

# --- ChromeOS ---

index chromeos 'target_os="chromeos"' || true

# --- Android ---

build/install-build-deps-android.sh

index android 'target_os="android"' || true

# --- Fuchsia ---

index fuchsia 'target_os="fuchsia"' || true

# --- Android Chromecast ---

index chromecast-android 'target_os="android" is_chromecast=true' || true

# --- Linux Chromecast ---

index chromecast-linux 'target_os="linux" is_chromecast=true' || true
