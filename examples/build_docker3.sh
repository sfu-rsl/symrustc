#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

param_llvm="" # --target=aarch64-linux-gnu -fno-discard-value-names -mllvm '-rng-seed=1'
param_exec="-o sample" # --target=aarch64-linux-gnu -fno-discard-value-names -mllvm '-rng-seed=1'

./build_llvm_ko-clang++.sh $param_llvm
./build_exec_ko-clang++.sh $param_exec
