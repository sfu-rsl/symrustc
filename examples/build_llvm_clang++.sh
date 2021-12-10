#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/llvm/clang++
    
    pushd generated/llvm/clang++
    clang++ -S -emit-llvm ../../../sample.cpp
    popd
    
    popd
done
