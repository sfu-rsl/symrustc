#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

source $SYMRUSTC_HOME_RS/parse_args.sh

#

pushd $SYMRUSTC_LIBAFL_TRACING_DIR >/dev/null

export SYMCC_INPUT_FILE="$PWD/$(date '+%F_%T' | tr -d ':-')"
echo "$@" > $SYMCC_INPUT_FILE

SYMRUSTC_BIN_ARGS=$SYMCC_INPUT_FILE \
../../target/debug/dump_constraints --plain-text --output output.txt -- \
    $SYMRUSTC_HOME_RS/symrustc_run.sh
cat output.txt

rm $SYMCC_INPUT_FILE

popd >/dev/null
