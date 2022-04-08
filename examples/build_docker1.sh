#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

param_exec="-fno-discard-value-names -o sample" # --target=aarch64-linux-gnu -mllvm '-rng-seed=1'

export SYMCC_LIBCXX_PATH=~/libcxx_symcc_install
./build_exec_sym++_simple_z3.sh $param_exec
