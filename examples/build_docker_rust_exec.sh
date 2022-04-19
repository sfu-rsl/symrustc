#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

for dir in "source_0_original_1a_rs 17 test" \
           "source_0_original_1b_rs 40 test" \
           "source_2_base_1a_rs 0" \
           "source_4_symcc_1_rs 3 -ne \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03" \
           "source_4_symcc_2_rs 9 test"
do
    dir=( $dir )
    input="${dir[@]:2}"

    echo $input | ${dir[0]}/target/debug/belcarra
    echo $input | ./hexdump.sh /dev/stdin \
        && [ $(ls /tmp/output | wc -l) -eq ${dir[1]} ] # check the "expected" number of answers

    rm -f /tmp/output/*
done
