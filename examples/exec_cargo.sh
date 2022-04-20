#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export SYMCC_NO_SYMBOLIC_INPUT=yes
SYMCC_RUNTIME_DIR=~/symcc_build/SymRuntime-prefix/src/SymRuntime-build

export RUSTFLAGS="-L${SYMCC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMCC_RUNTIME_DIR} -C passes=symcc -lSymRuntime"
export RUSTC=$BELCARRA_RUSTC

$BELCARRA_CARGO "$@"
