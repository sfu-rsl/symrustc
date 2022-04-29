#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args.sh

SYMRUSTC_DIR0="$SYMRUSTC_DIR"

for dir in "source_0_original_1a_rs 0 8 test" \
           "source_0_original_1b_rs 0 40 test" \
           "source_2_base_1a_rs 1 0" \
           "source_4_symcc_1_rs 0 3 -ne \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03" \
           "source_4_symcc_2_rs 0 9 test"
do
    dir=( $dir )

    export SYMRUSTC_DIR="$SYMRUSTC_DIR0/${dir[0]}"
    export SYMRUSTC_RUN_EXPECTED_CODE=${dir[1]}
    export SYMRUSTC_RUN_EXPECTED_COUNT=${dir[2]}
    $SYMRUSTC_HOME_RS/symrustc_run.sh "${dir[@]:3}"
done
