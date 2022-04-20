#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export SYMCC_INPUT_FILE=$BELCARRA_INPUT_FILE

$BELCARRA_EXAMPLE/../exec_rustc.sh $BELCARRA_INPUT_FILE "$@"
