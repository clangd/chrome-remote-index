#!/bin/bash
#===-- prepare.sh ---------------------------------------------------------===//
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===-----------------------------------------------------------------------===//
#
# Fetch Chromium sources and prepare the environment.
#
#===-----------------------------------------------------------------------===//

set -eux

cd /

rm -rf depot_tools
git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH="$PATH:$(readlink -f depot_tools)"

mkdir -p chromium
cd chromium

gclient metrics --opt-out

# Perform fetch only if this is for the first time. As fetch will fail
# otherwise.
if [ ! -f .gclient ]; then
  fetch --no-history --nohooks chromium
fi

echo "target_os = [ 'linux', 'android', 'chromeos', 'fuchsia' ]" >> .gclient

cd src

gclient sync --no-history

build/install-build-deps.py || true

gclient runhooks

echo "Finished preparing the environment"
