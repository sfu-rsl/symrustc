#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

if [[ -v SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_SOLVING ]] ; then
    mkdir -p target_cargo_on/debug
    curl -LO 'https://github.com/sfu-rsl/symrustc/raw/1.46.0_binary/'"$(echo $SYMRUSTC_LIBAFL_EXAMPLE | rev | cut -d / -f 1-2 | rev)"'/belcarra'
    chmod +x belcarra
    mv belcarra target_cargo_on/debug
else
    $SYMRUSTC_HOME_RS/symrustc_build.sh
fi
