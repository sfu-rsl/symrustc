#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export SYMCC_NO_SYMBOLIC_INPUT=yes

SYMCC_RUNTIME_DIR=~/symcc_build/SymRuntime-prefix/src/SymRuntime-build
export RUSTC=$BELCARRA_RUSTC

#

export PATH=~/symcc_build_clang:"$PATH" # e.g. for SymRustC programs explicitly using clang or clang++ in their build
CARGO_TARGET_DIR=$BELCARRA_EXAMPLE/target_cargo \
RUSTFLAGS="-L${SYMCC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMCC_RUNTIME_DIR} -C passes=symcc -lSymRuntime" \
    $BELCARRA_CARGO "$@"

