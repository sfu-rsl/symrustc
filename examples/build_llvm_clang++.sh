#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    cd "$dir"
    mkdir -p generated/llvm/clang++
    
    (cd generated/llvm/clang++ && clang++ -S -emit-llvm ../../../sample.cpp)
    
    cd -
done
