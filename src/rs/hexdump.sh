#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

hexdump="hexdump -v -C"
output_dir=$SYMCC_OUTPUT_DIR/..

#

$hexdump "$1" > $output_dir/hexdump_stdin

(ls $SYMCC_OUTPUT_DIR/* || true) | while read i
do
    echo -e "=============================\n$i"
    $hexdump "$i" | (git diff --color-words --no-index $output_dir/hexdump_stdin - || true) | tail -n +5
done 2>$output_dir/hexdump_stderr >$output_dir/hexdump_stdout
