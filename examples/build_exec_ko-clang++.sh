#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/exec/ko-clang++

    pushd generated/exec/ko-clang++
    ../../../../../../bin/ko-clang++ "$@" ../../../sample.cpp
    popd
    
    popd
done
