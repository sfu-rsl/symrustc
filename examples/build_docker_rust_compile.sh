#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export PATH=~/symcc_build_clang:"$PATH"

#

for dir in source_0_original_1a_rs \
           source_0_original_1b_rs \
           source_2_base_1a_rs \
           source_4_symcc_1_rs \
           "source_4_symcc_2_rs -- -Clinker=clang++" # Semantically: should symlink to sym++ to enable concolic annotation.
do
    dir=( $dir )
    pushd ${dir[0]}
    ~/exec_cargo.sh rustc "${dir[@]:1}"
    popd
done
