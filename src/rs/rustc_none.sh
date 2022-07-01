#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args0.sh

export SYMCC_NO_SYMBOLIC_INPUT=yes

$SYMRUSTC_HOME_RS/rustc.sh $SYMRUSTC_INPUT_FILE "$@"
