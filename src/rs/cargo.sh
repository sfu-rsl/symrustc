#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export SYMCC_NO_SYMBOLIC_INPUT=yes

SYMCC_RUNTIME_DIR=~/symcc_build/SymRuntime-prefix/src/SymRuntime-build
export RUSTFLAGS="-L${SYMCC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMCC_RUNTIME_DIR}"
export RUSTC=$SYMRUSTC_RUSTC

#

# Note: Changing $PATH is optional. For instance, it can be done for supporting Rust programs using clang or clang++ in their build.
PATH=~/clang_build:"$PATH" \
CARGO_TARGET_DIR=$SYMRUSTC_EXAMPLE/target_cargo_off \
    fork $SYMRUSTC_CARGO "$@"

# Note: Same remarks apply for SymRustC programs. However here, we have to use the "concolic SymCC" versions of clang or clang++.
PATH=~/symcc_build_clang:"$PATH" \
CARGO_TARGET_DIR=$SYMRUSTC_EXAMPLE/target_cargo_on \
RUSTFLAGS="$RUSTFLAGS -C passes=symcc -lSymRuntime" \
    fork $SYMRUSTC_CARGO "$@"

wait_all
