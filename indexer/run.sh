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

# Remove snapcraft from dependency list: installing it is not feasible inside
# Docker.
sed -i '/if package_exists snapcraft/,/fi/d' ./build/install-build-deps.sh
./build/install-build-deps.sh

gclient runhooks

gn gen out/Default

ninja -C out/Default/ -t targets all | grep -i '^gen/' | grep -E "\.(cpp|h|inc|cc)\:" | cut -d':' -f1 | xargs autoninja -C out/Default

tools/clang/scripts/generate_compdb.py -p out/Default > compile_commands.json

$CLANGD_INDEXER --executor=all-TUs compile_commands.json > /chrome.idx

7z a chrome-index-$(date -u +%Y%m%d).zip /chrome.idx

CURRENT_COMMIT=$(git rev-parse --short HEAD)

gh release create --repo clangd/chrome-remote-index --title="Index at $(date -u +%Y-%m-%d)" --notes="Index with Default config options at $CURRENT_COMMIT commit." $CURRENT_COMMIT chrome-index-$(date -u +%Y%m%d).zip
