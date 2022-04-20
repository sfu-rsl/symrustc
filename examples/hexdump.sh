#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

hexdump="hexdump -v -C"

#

$hexdump "$1" > /tmp/belcarra_stdin_hex

(ls /tmp/output/* || true) | while read i
do
    echo -e "=============================\n$i"
    $hexdump "$i" | (git diff --color-words --no-index /tmp/belcarra_stdin_hex - || true) | tail -n +5
done
