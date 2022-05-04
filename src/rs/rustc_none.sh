#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

export SYMCC_NO_SYMBOLIC_INPUT=yes

$SYMRUSTC_HOME_RS/rustc.sh $SYMRUSTC_INPUT_FILE "$@"
