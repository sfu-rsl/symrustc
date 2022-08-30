#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args0.sh

export SYMCC_NO_SYMBOLIC_INPUT=yes
export RUSTFLAGS="-L${SYMRUSTC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMRUSTC_RUNTIME_DIR}"
export RUSTC=$SYMRUSTC_RUSTC

#

if [[ -v SYMRUSTC_EXEC_CONCOLIC_OFF ]] ; then
# Note: Changing $PATH is optional. For instance, it can be done for supporting Rust programs using clang or clang++ in their build.
PATH=~/clang_symcc_off:"$PATH" \
CARGO_TARGET_DIR=$SYMRUSTC_DIR/target_cargo_off \
    eval fork "$@"
fi

if [[ ! -v SYMRUSTC_SKIP_CONCOLIC_ON ]] ; then
# Note: Same remarks apply for SymRustC programs. However here, we have to use the "concolic SymCC" versions of clang or clang++.
PATH=~/clang_symcc_on:"$PATH" \
CARGO_TARGET_DIR=$SYMRUSTC_DIR/target_cargo_on \
RUSTFLAGS="$RUSTFLAGS -C passes=symcc -lSymRuntime" \
    eval fork "$@"
fi

wait_all
