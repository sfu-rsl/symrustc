#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

cd ~/symcc_source/util/symcc_fuzzing_helper

declare -i err=0
$SYMRUSTC_HOME_RS/env.sh $SYMRUSTC_CARGO install --path $PWD --locked || err=$?

if ((err != 0)); then
    if [[ -v SYMRUSTC_SKIP_FAIL ]]; then
        echo "error exit code: $err" >&2
    else
        exit "$err"
    fi
fi
