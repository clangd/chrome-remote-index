#!/bin/bash
#===-- entry_point.sh -----------------------------------------------------===//
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===-----------------------------------------------------------------------===//
#
# Docker entry point wrapper.
#
#===-----------------------------------------------------------------------===//

set -eux

/prepare.sh

# Run one indexing cycle immediately at startup.
/run.sh

# Start cron only after initial indexing finishes.
cron
tail -f /var/log/indexer.log
