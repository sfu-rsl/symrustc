#!/bin/bash

set -euxo pipefail

param_llvm="-fno-discard-value-names" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'
param_exec="-fno-discard-value-names -o sample" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'

./build_llvm_clang++.sh $param_llvm
./build_exec_clang++.sh $param_exec
