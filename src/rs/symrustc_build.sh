#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args.sh

if [[ ! -v SYMRUSTC_BUILD_COMP_CONCOLIC ]] ; then
    SYMRUSTC_BUILD_COMP_CONCOLIC=false
fi

#

source $SYMRUSTC_HOME_RS/wait_all.sh

#

export SYMRUSTC_TARGET_NAME=symrustc/build

if eval $SYMRUSTC_BUILD_COMP_CONCOLIC
   # TODO: at the time of writing, examples having several Rust source files (e.g. comprising build.rs) are not yet implemented
then
    export SYMRUSTC_INPUT_FILE="$SYMRUSTC_DIR/src/main.rs"

    CARGO_TARGET_DIR=target_rustc_none_on fork $SYMRUSTC_HOME_RS/rustc_none.sh -Z new-llvm-pass-manager=no -C passes=symcc -lSymRuntime "$@"
    CARGO_TARGET_DIR=target_rustc_none_off fork $SYMRUSTC_HOME_RS/rustc_none.sh "$@"
    CARGO_TARGET_DIR=target_rustc_file_on fork $SYMRUSTC_HOME_RS/rustc_file.sh -Z new-llvm-pass-manager=no -C passes=symcc -lSymRuntime "$@"
    CARGO_TARGET_DIR=target_rustc_file_off fork $SYMRUSTC_HOME_RS/rustc_file.sh "$@"
    CARGO_TARGET_DIR=target_rustc_stdin_on fork $SYMRUSTC_HOME_RS/rustc_stdin.sh -Z new-llvm-pass-manager=no -C passes=symcc -lSymRuntime "$@"
    CARGO_TARGET_DIR=target_rustc_stdin_off fork $SYMRUSTC_HOME_RS/rustc_stdin.sh "$@"
fi

fork $SYMRUSTC_HOME_RS/env0.sh $SYMRUSTC_CARGO rustc --manifest-path "$SYMRUSTC_DIR/Cargo.toml" "$@"

wait_all

#

if [[ ! -v SYMRUSTC_HIDE_RESULT ]]; then
    source $SYMRUSTC_HOME_RS/symrustc_build_show.sh
fi
