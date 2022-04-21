#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/llvm/ko-clang++

    pushd generated/llvm/ko-clang++
    ../../../../../../bin/ko-clang++ -S -emit-llvm "$@" ../../../sample.cpp
    popd
    
    popd
done
