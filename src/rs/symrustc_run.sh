#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

source $SYMRUSTC_HOME_RS/parse_args.sh

if [[ -v SYMRUSTC_RUN_EXPECTED_CODE ]] ; then
    declare -i SYMRUSTC_RUN_EXPECTED_CODE=$SYMRUSTC_RUN_EXPECTED_CODE
else
    declare -i SYMRUSTC_RUN_EXPECTED_CODE=0
fi

#

SYMRUSTC_TARGET_NAME=symrustc/run

function symrustc_exec () {
    local target="$1"; shift
    local input="$@"

    local target0="$SYMRUSTC_DIR/$target"
    local output_dir="$target0/$SYMRUSTC_TARGET_NAME"
    export SYMCC_OUTPUT_DIR="$output_dir/output"

    mkdir -p "$SYMCC_OUTPUT_DIR"

    declare -i code_actual=0
    echo $input | "$(find -L "$target0/debug" -maxdepth 1 -type f -executable | grep . -m 1)" || code_actual=$?
    echo $input | $SYMRUSTC_HOME_RS/hexdump.sh /dev/stdin

    ls $output_dir/output | wc -l >&2
    cat $output_dir/hexdump_stdout >&2
    cat $output_dir/hexdump_stderr >&2

    if (( $SYMRUSTC_RUN_EXPECTED_CODE != $code_actual )); then
        echo "$target: Unexpected exit code: $code_actual" >&2
        if [[ ! -v SYMRUSTC_SKIP_FAIL ]] ; then
            exit 1
        fi
    fi
}

for target0 in target_cargo target_rustc_none target_rustc_file target_rustc_stdin
do
    target_on=${target0}_on
    if [[ -d "$SYMRUSTC_DIR/$target_on" ]]; then
        symrustc_exec $target_on "$@"

        if [[ -v SYMRUSTC_RUN_EXPECTED_COUNT ]] && [[ $(ls "$SYMCC_OUTPUT_DIR" | wc -l) -ne $SYMRUSTC_RUN_EXPECTED_COUNT ]] ; then
            echo "$target_on: check expected to succeed" >&2
            if [[ ! -v SYMRUSTC_SKIP_FAIL ]] ; then
                exit 1
            fi
        fi
    fi

    target_off=${target0}_off
    if [[ -d "$SYMRUSTC_DIR/$target_off" ]]; then
        symrustc_exec $target_off "$@"

        declare -i count_actual=$(ls "$SYMCC_OUTPUT_DIR" | wc -l)
        if (( $count_actual != 0 )); then
            if [[ -v SYMRUSTC_RUN_EXPECTED_COUNT ]] && (( $count_actual > $SYMRUSTC_RUN_EXPECTED_COUNT )); then
                echo "$target_off: check not expected to succeed" >&2
                exit 1
            else
                echo "warning: $SYMRUSTC_DIR/$target_off not empty" >&2
            fi
        fi
    fi
done
