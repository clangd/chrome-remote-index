#!/bin/bash
#===-- run.sh -------------------------------------------------------------===//
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===----------------------------------------------------------------------===//
#
# Produce Chromium index.
#
#===----------------------------------------------------------------------===//

set -eux

# Prepare the environment: download all necessary binaries and fetch the source
# code.

echo "Downloading clangd indexer"

python3 download_latest_release_assets.py --output-name clangd_indexing_tools.zip  --asset-prefix clangd_indexing_tools-linux

unzip clangd_indexing_tools.zip

export CLANGD_INDEXER=$(find . -name 'clangd-indexer' | xargs readlink -f)

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH="$PATH:$(readlink -f depot_tools)"

mkdir chromium
cd chromium

gclient metrics --opt-out

fetch --nohooks chromium

cd src

mkdir -p out/Default
export BUILD_DIR=$(readlink -f out/Default)

echo "target_os = [ 'linux', 'android', 'chromeos', 'fuchsia' ]" >> ../.gclient

gclient sync

gclient runhooks

# Create a release, will be empty for now and incrementally populated
# throughout the indexing pipeline.

DATE=$(date -u +%Y%m%d)

COMMIT=$(git rev-parse --short HEAD)

gh release create $COMMIT --repo clangd/chrome-remote-index \
  --title="Index at $DATE" \
  --notes="Chromium index artifacts at $COMMIT with project root \`$PWD\`."

# Configurations for some build might fail but the indexing pipeline shouldn't
# because some indices could still be produced.
set +e

# The indexing pipeline is common. Each platform will only have to do the
# preparation step (set up the build configuration and install dependencies).

# $1: Platform name.
# $2: GN arguments for the chosen platform.
# TODO: Add logging for failures.
index() {
  PLATFORM=$1

  GN_ARGS=$2

  echo "Indexing for $PLATFORM"

  gn gen --args=$GN_ARGS $BUILD_DIR

  # Build generated files.
  ninja -C $BUILD_DIR -t targets all | grep -i '^gen/' | grep -E "\.(cpp|h|inc|cc)\:" | cut -d':' -f1 | xargs autoninja -C $BUILD_DIR

  # Get compile_commands.json for clangd-indexer.
  tools/clang/scripts/generate_compdb.py -p $BUILD_DIR > compile_commands.json

  $CLANGD_INDEXER --executor=all-TUs compile_commands.json > /chrome-$PLATFORM.idx

  7z a chrome-index-$PLATFORM-$DATE.zip /chrome-$PLATFORM.idx

  gh release upload --repo clangd/chrome-remote-index $COMMIT chrome-index-$PLATFORM-$DATE.zip

  # Clean up the build directory afterwards.
  rm -rf $BUILD_DIR
}

# --- Linux ---

# Remove snapcraft from dependency list: installing it is not feasible inside
# Docker.
sed -i '/if package_exists snapcraft/,/fi/d' ./build/install-build-deps.sh
./build/install-build-deps.sh

index linux 'target_os="linux"'

# --- ChromeOS ---

index chromeos 'target_os="chromeos"'

# --- Android ---

build/install-build-deps-android.sh

index android 'target_os="android"'

# --- Fuchsia ---

index fuchsia 'target_os="fuchsia"'

# --- Android Chromecast ---

index chromecast-android 'target_os="android" is_chromecast=true'

# --- Linux Chromecast ---

index chromecast-linux 'target_os="linux" is_chromecast=true'
