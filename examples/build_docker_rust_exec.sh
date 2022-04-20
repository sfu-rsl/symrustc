#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

BELCARRA_TARGET_NAME=belcarra/source

for dir in "source_0_original_1a_rs 0 true 17 test" \
           "source_0_original_1b_rs 0 true 40 test" \
           "source_2_base_1a_rs 1 true 0" \
           "source_4_symcc_1_rs 0 false 3 -ne \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03" \
           "source_4_symcc_2_rs 0 false 9 test"
do
    dir=( $dir )

    targets=( target_cargo )
    if eval ${dir[2]}; then
        targets+=( target_rustc_file target_rustc_stdin )
    fi
    
    for target0 in ${targets[@]}
    do
        declare -i code_expected=${dir[1]}
        target=${dir[0]}/${target0}
        input="${dir[@]:4}"
    
        output_dir=$BELCARRA_EXAMPLE0/$target/$BELCARRA_TARGET_NAME
        export SYMCC_OUTPUT_DIR=$output_dir/output

        mkdir -p $SYMCC_OUTPUT_DIR
        
        declare -i code_actual=0
        echo $input | $target/debug/belcarra || code_actual=$?
        echo $input | ./hexdump.sh /dev/stdin

        ls $output_dir/output | wc -l
        cat $output_dir/hexdump_stdout
        cat $output_dir/hexdump_stderr
    
        if (( $code_expected != $code_actual )); then
            echo "Unexpected exit code" >&2
            exit 1
        fi
        
        [ $(ls $SYMCC_OUTPUT_DIR | wc -l) -eq ${dir[3]} ]
    done
done
