#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/exec/clang++
    
    pushd generated/exec/clang++
    clang++-$BELCARRA_LLVM_VERSION "$@" ../../../sample.cpp
    popd
    
    popd
done
