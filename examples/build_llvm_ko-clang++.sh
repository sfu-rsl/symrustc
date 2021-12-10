#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    cd "$dir"
    mkdir -p generated/llvm/ko-clang++

    (cd generated/llvm/ko-clang++ && ../../../../../../bin/ko-clang++ -S -emit-llvm ../../../sample.cpp)
    
    cd -
done
