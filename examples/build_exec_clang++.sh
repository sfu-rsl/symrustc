#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    cd "$dir"
    mkdir -p generated/exec/clang++
    
    (cd generated/exec/clang++ && clang++ -o sample ../../../sample.cpp)
    
    cd -
done
