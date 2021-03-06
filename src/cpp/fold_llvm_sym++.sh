#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/llvm/clang++_isystem

    pushd generated/llvm/clang++_isystem
    clang++-$SYMRUSTC_LLVM_VERSION \
        -isystem ~/libcxx_symcc_install/include/c++/v1 \
        -stdlib=libc++ \
        -S -emit-llvm "$@" ../../../sample.cpp
    popd
    
    mkdir -p generated/llvm/sym++

    pushd generated/llvm/sym++
    ~/symcc_build/sym++ -S -emit-llvm "$@" ../../../sample.cpp
    popd
    
    popd
done
