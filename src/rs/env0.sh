#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export SYMCC_NO_SYMBOLIC_INPUT=yes

SYMCC_RUNTIME_DIR=~/symcc_build/SymRuntime-prefix/src/SymRuntime-build
export RUSTFLAGS="-L${SYMCC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMCC_RUNTIME_DIR}"
export RUSTC=$SYMRUSTC_RUSTC

#

if [[ ! -v SYMRUSTC_SKIP_CONCOLIC_OFF ]] ; then
# Note: Changing $PATH is optional. For instance, it can be done for supporting Rust programs using clang or clang++ in their build.
PATH=~/clang_symcc_off:"$PATH" \
CARGO_TARGET_DIR=$SYMRUSTC_EXAMPLE/target_cargo_off \
    eval fork "$@"
fi

if [[ ! -v SYMRUSTC_SKIP_CONCOLIC_ON ]] ; then
# Note: Same remarks apply for SymRustC programs. However here, we have to use the "concolic SymCC" versions of clang or clang++.
PATH=~/clang_symcc_on:"$PATH" \
CARGO_TARGET_DIR=$SYMRUSTC_EXAMPLE/target_cargo_on \
RUSTFLAGS="$RUSTFLAGS -C passes=symcc -lSymRuntime" \
    eval fork "$@"
fi

wait_all
