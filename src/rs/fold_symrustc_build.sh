#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args.sh

source $SYMRUSTC_HOME_RS/wait_all.sh

export SYMRUSTC_TARGET_NAME=symrustc/build
export SYMRUSTC_HIDE_RESULT=yes

SYMRUSTC_DIR0="$SYMRUSTC_DIR"

for dir in "source_0_original_1a_rs true" \
           "source_0_original_1b_rs true" \
           "source_2_base_1a_rs true" \
           "source_4_symcc_1_rs false" \
           "source_4_symcc_2_rs false -- -Clinker=clang++" # Semantically: should symlink to sym++ to enable concolic annotation.
do
    dir=( $dir )
    
    export SYMRUSTC_DIR="$SYMRUSTC_DIR0/${dir[0]}"
    export SYMRUSTC_BUILD_COMP_CONCOLIC=${dir[1]}
    fork $SYMRUSTC_HOME_RS/symrustc_build.sh "${dir[@]:2}"
done

wait_all

#

for dir in "source_0_original_1a_rs true" \
           "source_0_original_1b_rs true" \
           "source_2_base_1a_rs true" \
           "source_4_symcc_1_rs false" \
           "source_4_symcc_2_rs false"
do
    dir=( $dir )
    
    SYMRUSTC_DIR="$SYMRUSTC_DIR0/${dir[0]}"
    SYMRUSTC_BUILD_COMP_CONCOLIC=${dir[1]}
    source $SYMRUSTC_HOME_RS/symrustc_build_show.sh
done
