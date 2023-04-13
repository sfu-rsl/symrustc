#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

export SYMRUSTC_LIBAFL_SOLVING_DIR=$SYMRUSTC_LIBAFL_SOLVING_INST_DIR
$SYMRUSTC_HOME_RS/libafl_solving_run.sh "$@"
