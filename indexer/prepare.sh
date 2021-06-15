#!/bin/bash
#===-- prepare.sh ---------------------------------------------------------===//
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===----------------------------------------------------------------------===//
#
# Fetch Chromium sources and prepare the environment.
#
#===----------------------------------------------------------------------===//

set -eux

cd /

git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH="$PATH:$(readlink -f depot_tools)"

mkdir chromium
cd chromium

gclient metrics --opt-out

fetch --nohooks chromium

echo "target_os = [ 'linux', 'android', 'chromeos', 'fuchsia' ]" >> .gclient

cd src

gclient sync

# Remove snapcraft from dependency list: installing it is not feasible inside
# Docker.
sed -i '/if package_exists snapcraft/,/fi/d' ./build/install-build-deps.sh
./build/install-build-deps.sh

build/install-build-deps-android.sh

gclient runhooks

echo "Finished preparing the environment"
