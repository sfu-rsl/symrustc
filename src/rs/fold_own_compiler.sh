#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

source $SYMRUSTC_HOME_RS/wait_all.sh

export SYMRUSTC_TARGET_NAME=belcarra/compiler

for dir in "source_0_original_1a_rs true" \
           "source_0_original_1b_rs true" \
           "source_2_base_1a_rs true" \
           "source_4_symcc_1_rs false" \
           "source_4_symcc_2_rs false -- -Clinker=clang++" # Semantically: should symlink to sym++ to enable concolic annotation.
do
    dir=( $dir )
    
    export SYMRUSTC_EXAMPLE=$SYMRUSTC_EXAMPLE0/${dir[0]}

    if eval ${dir[1]}
       # TODO: at the time of writing, examples having several Rust source files (e.g. comprising build.rs) are not yet implemented
    then
        export SYMRUSTC_INPUT_FILE=$SYMRUSTC_EXAMPLE/src/main.rs

        CARGO_TARGET_DIR=target_rustc_none_on fork $SYMRUSTC_HOME_RS/rustc_none.sh -C passes=symcc -lSymRuntime "${dir[@]:2}"
        CARGO_TARGET_DIR=target_rustc_none_off fork $SYMRUSTC_HOME_RS/rustc_none.sh "${dir[@]:2}"
        CARGO_TARGET_DIR=target_rustc_file_on fork $SYMRUSTC_HOME_RS/rustc_file.sh -C passes=symcc -lSymRuntime "${dir[@]:2}"
        CARGO_TARGET_DIR=target_rustc_file_off fork $SYMRUSTC_HOME_RS/rustc_file.sh "${dir[@]:2}"
        CARGO_TARGET_DIR=target_rustc_stdin_on fork $SYMRUSTC_HOME_RS/rustc_stdin.sh -C passes=symcc -lSymRuntime "${dir[@]:2}"
        CARGO_TARGET_DIR=target_rustc_stdin_off fork $SYMRUSTC_HOME_RS/rustc_stdin.sh "${dir[@]:2}"
    fi

    fork $SYMRUSTC_HOME_RS/cargo.sh rustc --manifest-path $SYMRUSTC_EXAMPLE/Cargo.toml "${dir[@]:2}"
done

wait_all

#

targets+=( target_rustc_none target_rustc_file target_rustc_stdin )

for dir in "source_0_original_1a_rs true" \
           "source_0_original_1b_rs true" \
           "source_2_base_1a_rs true" \
           "source_4_symcc_1_rs false" \
           "source_4_symcc_2_rs false"
do
    dir=( $dir )

    if eval ${dir[1]}; then
        for target0 in ${targets[@]}
        do
            for target_pass in on off
            do
                target=$SYMRUSTC_EXAMPLE0/${dir[0]}/${target0}_$target_pass
                ls $target/$SYMRUSTC_TARGET_NAME/output | wc -l
                cat $target/$SYMRUSTC_TARGET_NAME/hexdump_stdout
                cat $target/$SYMRUSTC_TARGET_NAME/hexdump_stderr
            done
        done
    fi
done
