#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

export SYMRUSTC_DIR=$PWD

pushd $SYMRUSTC_LIBAFL_TRACING_DIR >/dev/null

../../target/debug/dump_constraints --plain-text --output output_build.txt -- \
    $SYMRUSTC_HOME_RS/symrustc_build.sh

popd >/dev/null
