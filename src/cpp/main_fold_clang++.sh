#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

param_llvm="-fno-discard-value-names" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'
param_exec="-fno-discard-value-names -o sample" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'

$SYMRUSTC_HOME_CPP/fold_llvm_clang++.sh $param_llvm
$SYMRUSTC_HOME_CPP/fold_exec_clang++.sh $param_exec
