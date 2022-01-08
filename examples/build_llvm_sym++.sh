#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/llvm/sym++

    pushd generated/llvm/sym++
    sym++ -S -emit-llvm "$@" ../../../sample.cpp
    popd
    
    popd
done
