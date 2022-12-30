#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

param_exec="-fno-discard-value-names -o sample" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'

$SYMRUSTC_HOME_CPP/fold_exec_sym++_simple_z3.sh $param_exec || echo "error exit code: $?" >&2 # FIXME: https://github.com/llvm/llvm-project/issues/57104
