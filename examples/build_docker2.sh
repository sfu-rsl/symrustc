#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

param_llvm="-fno-discard-value-names" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'
param_exec="-fno-discard-value-names -o sample" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'

./build_llvm_sym++.sh $param_llvm
./build_exec_sym++_qsym.sh $param_exec
