#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    cd "$dir"
    mkdir -p generated/exec/ko-clang++
    
    (cd generated/exec/ko-clang++ && ../../../../../../bin/ko-clang++ -o sample ../../../sample.cpp)
    
    cd -
done
