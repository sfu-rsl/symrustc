#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

param_llvm="-fno-discard-value-names" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'
param_exec="-fno-discard-value-names -o sample" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'

$BELCARRA_HOME_CPP/fold_llvm_sym++.sh $param_llvm
$BELCARRA_HOME_CPP/fold_exec_sym++_qsym.sh $param_exec
