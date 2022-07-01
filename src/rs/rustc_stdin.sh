#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args0.sh

cat $SYMRUSTC_INPUT_FILE | $SYMRUSTC_HOME_RS/rustc.sh - "$@"
