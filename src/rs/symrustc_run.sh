#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

SYMRUSTC_TARGET_NAME=belcarra/source

SYMRUSTC_EXAMPLE="$(realpath "$1")"; shift
declare -i code_expected=$1; shift
concolic_rustc=$1; shift
count_expected=$1; shift

SYMRUSTC_EXAMPLE0="$(dirname "$SYMRUSTC_EXAMPLE")"
target_dir="$(basename "$SYMRUSTC_EXAMPLE")"

function belcarra_exec () {
    local target="$1"; shift
    local input="$@"

    local target0=$SYMRUSTC_EXAMPLE0/$target
    local output_dir=$target0/$SYMRUSTC_TARGET_NAME
    export SYMCC_OUTPUT_DIR=$output_dir/output

    mkdir -p $SYMCC_OUTPUT_DIR

    declare -i code_actual=0
    echo $input | $target0/debug/belcarra || code_actual=$?
    echo $input | $SYMRUSTC_HOME_RS/hexdump.sh /dev/stdin

    ls $output_dir/output | wc -l
    cat $output_dir/hexdump_stdout
    cat $output_dir/hexdump_stderr

    if (( $code_expected != $code_actual )); then
        echo "$target: Unexpected exit code: $code_actual" >&2
        if [[ ! -v SYMRUSTC_SKIP_FAIL ]] ; then
            exit 1
        fi
    fi
}

targets=( target_cargo )
if eval $concolic_rustc; then
    targets+=( target_rustc_none target_rustc_file target_rustc_stdin )
fi

for target0 in ${targets[@]}
do
    belcarra_exec $target_dir/${target0}_on "$@"
    if [ $(ls $SYMCC_OUTPUT_DIR | wc -l) -ne $count_expected ] ; then
        echo "$target: check expected to succeed" >&2
        if [[ ! -v SYMRUSTC_SKIP_FAIL ]] ; then
            exit 1
        fi
    fi
    
    target=$target_dir/${target0}_off
    belcarra_exec $target "$@"
    
    declare -i count_actual=$(ls $SYMCC_OUTPUT_DIR | wc -l)
    if (( $count_actual != 0 )); then
        if (( $count_actual >= $count_expected )); then
            echo "$target: check not expected to succeed" >&2
            exit 1
        else
            echo "warning: $SYMRUSTC_EXAMPLE0/$target not empty" >&2
        fi
    fi
done
