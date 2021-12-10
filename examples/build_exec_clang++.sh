#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/exec/clang++
    
    pushd generated/exec/clang++
    clang++ -o sample ../../../sample.cpp
    popd
    
    popd
done
