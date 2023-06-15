#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

date_now="$(date '+%F_%T' | tr -d ':-')"

#

cargo fuzz build # force the build to occur outside of our measured benchmark duration

$SYMRUSTC_HOME_RS/cargo_fuzz0.sh 2>&1 | tee "$HOME/cargo_fuzz_${date_now}"
