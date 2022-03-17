#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

RUSTFLAGS='-L/symcc_build/SymRuntime-prefix/src/SymRuntime-build -Clink-arg=-Wl,-rpath,/symcc_build/SymRuntime-prefix/src/SymRuntime-build -C passes=symcc -lSymRuntime' \
RUSTC=~/stage2/bin/rustc \
cargo rustc -- \
  -Clinker=clang++ # Semantically: should symlink to sym++ to enable concolic annotation.
