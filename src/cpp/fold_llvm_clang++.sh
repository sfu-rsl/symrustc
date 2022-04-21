#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/llvm/clang++
    
    pushd generated/llvm/clang++
    clang++-10 -S -emit-llvm "$@" ../../../sample.cpp
    popd
    
    popd
done
