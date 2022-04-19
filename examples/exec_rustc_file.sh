#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

input_file=$BELCARRA_EXAMPLE/src/main.rs

export SYMCC_INPUT_FILE="$input_file"

$BELCARRA_EXAMPLE/../exec_rustc.sh "$input_file" "$input_file"
