#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    cd "$dir"
    mkdir -p generated/llvm/sym++

    (cd generated/llvm/sym++ && sym++ -S -emit-llvm ../../../sample.cpp)
    
    cd -
done
