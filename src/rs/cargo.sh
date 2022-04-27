#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export SYMCC_NO_SYMBOLIC_INPUT=yes

SYMCC_RUNTIME_DIR=~/symcc_build/SymRuntime-prefix/src/SymRuntime-build
export RUSTFLAGS="-L${SYMCC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMCC_RUNTIME_DIR}"
export RUSTC=$BELCARRA_RUSTC

#

CARGO_TARGET_DIR=$BELCARRA_EXAMPLE/target_cargo_off \
    fork $BELCARRA_CARGO "$@" # Note: if the program relies on clang or clang++ in its build, then a tentative to find it in $PATH will typically be made (in this case, the environment is assumed to contain the binary in search; this can be done by natively installing the necessary on the OS side).

export PATH=~/symcc_build_clang:"$PATH" # e.g. for SymRustC programs explicitly using clang or clang++ in their build
CARGO_TARGET_DIR=$BELCARRA_EXAMPLE/target_cargo_on \
RUSTFLAGS="$RUSTFLAGS -C passes=symcc -lSymRuntime" \
    fork $BELCARRA_CARGO "$@"

wait_all
