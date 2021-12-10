#!/bin/bash

set -euxo pipefail

for dir in source*cpp
do
    pushd "$dir"
    mkdir -p generated/exec/sym++_qsym
    
    pushd generated/exec/sym++_qsym
    sym++ -o sample ../../../sample.cpp
    echo test | (./sample || true) 2>&1 | tee output
    csplit -f output_split output '/_sym_push_path_constraint /' '{*}'
    if [[ $(ls output_split?* | wc -l) == "1" ]]
    then
        rm output_split00
    fi
    popd
    popd
done
