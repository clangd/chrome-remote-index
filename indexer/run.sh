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

# -- Create a release, will be empty for now.

DATE=$(date -u +%Y%m%d)

CURRENT_COMMIT=$(git rev-parse --short HEAD)

gh release create $CURRENT_COMMIT --repo clangd/chrome-remote-index \
  --title="Index at $DATE" \
  --notes="Chromium index artifacts at $CURRENT_COMMIT with project root `$PWD`."

# $1: the platform name.
index() {
  echo "Indexing for $1"

  ninja -C $BUILD_DIR -t targets all | grep -i '^gen/' | grep -E "\.(cpp|h|inc|cc)\:" | cut -d':' -f1 | xargs autoninja -C $BUILD_DIR

  tools/clang/scripts/generate_compdb.py -p $BUILD_DIR > compile_commands.json

  $CLANGD_INDEXER --executor=all-TUs compile_commands.json > /chrome-$1.idx

  7z a chrome-index-$1-$DATE.zip /chrome-$1.idx

  gh release upload $CURRENT_COMMIT chrome-index-$1-$DATE.zip

  # Clean up the build directory afterwards.
  rm -rf $BUILD_DIR
}

# --- Linux ---

PLATFORM="linux"

# Remove snapcraft from dependency list: installing it is not feasible inside
# Docker.
sed -i '/if package_exists snapcraft/,/fi/d' ./build/install-build-deps.sh
./build/install-build-deps.sh

gn gen --args='target_os="linux"' $BUILD_DIR

index $PLATFORM

# --- ChromeOS ---

PLATFORM="chromeos"

gn gen --args='target_os="chromeos"' $BUILD_DIR

index $PLATFORM

# --- Android ---

PLATFORM="android"

build/install-build-deps-android.sh

gn gen --args='target_os="android"' $BUILD_DIR

index $PLATFORM

# --- Fuchsia ---

PLATFORM="fuchsia"

gn gen --args='target_os="fuchsia"' $BUILD_DIR

index $PLATFORM

# --- Android Chromecast ---

PLATFORM="chromecast-android"

gn gen --args='target_os="android" is_chromecast=true' $BUILD_DIR

index $PLATFORM

# --- Linux Chromecast ---

PLATFORM="chromecast-linux"

gn gen --args='target_os="linux" is_chromecast=true' $BUILD_DIR

index $PLATFORM
