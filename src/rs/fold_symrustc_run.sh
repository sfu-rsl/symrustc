#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

for dir in "source_0_original_1a_rs 0 true 17 test" \
           "source_0_original_1b_rs 0 true 40 test" \
           "source_2_base_1a_rs 1 true 0" \
           "source_4_symcc_1_rs 0 false 3 -ne \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03" \
           "source_4_symcc_2_rs 0 false 9 test"
do
    dir=( $dir )
    
    $SYMRUSTC_HOME_RS/symrustc_run.sh "$SYMRUSTC_EXAMPLE0/${dir[0]}" "${dir[@]:1}"
done
