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

set -eu

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

mkdir -p out/Build
export BUILD_DIR=$(readlink -f out/Build)

DATE=$(date -u +%Y%m%d)

# $1 is the directory where the build will live.
# $2 is the platform name.
# $3 is the date that will be put into the index filename.
index() {
  gclient sync -D

  gclient runhooks

  gn gen $1

  ninja -C $1 -t targets all | grep -i '^gen/' | grep -E "\.(cpp|h|inc|cc)\:" | cut -d':' -f1 | xargs autoninja -C $1

  tools/clang/scripts/generate_compdb.py -p $1 > compile_commands.json

  $CLANGD_INDEXER --executor=all-TUs compile_commands.json > /chrome-$2.idx

  7z a chrome-index-$2-$3.zip /chrome-$2.idx

  # Clean up the build directory afterwards.
  rm -rf $1
}

# --- Linux ---

PLATFORM="linux"

echo "Indexing for $PLATFORM"

# Remove snapcraft from dependency list: installing it is not feasible inside
# Docker.
sed -i '/if package_exists snapcraft/,/fi/d' ./build/install-build-deps.sh
./build/install-build-deps.sh

index() "$BUILD_DIR" "$PLATFORM" "$DATE"

# --- Android ---

PLATFORM="android"

echo "Indexing for $PLATFORM"

echo "target_os = [ '$PLATFORM' ]" >> ../.gclient

build/install-build-deps-android.sh

index() "$BUILD_DIR" "$PLATFORM" "$DATE"

# --- Fuchsia ---

PLATFORM="fuchsia"

echo "Indexing for $PLATFORM"

sed -i '$d' ../.gclient

echo "target_os = [ '$PLATFORM' ]" >> ../.gclient

index() "$BUILD_DIR" "$PLATFORM" "$DATE"

# --- ChromeOS ---

PLATFORM="chromeos"

echo "Indexing for $PLATFORM"

sed -i '$d' ../.gclient

echo "target_os = [ '$PLATFORM' ]" >> ../.gclient

index() "$BUILD_DIR" "$PLATFORM" "$DATE"

# -- Finish the job ---

CURRENT_COMMIT=$(git rev-parse --short HEAD)

gh release create --repo clangd/chrome-remote-index --title="Index at $DATE" --notes="Index with at $CURRENT_COMMIT commit." $CURRENT_COMMIT \
  chrome-index-linux-$DATE.zip \
  chrome-index-android-$DATE.zip \
  chrome-index-fuchsia-$DATE.zip \
  chrome-index-chromeos-$DATE.zip
