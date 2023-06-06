#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

export PATH=$SYMRUSTC_USER/clang_symcc_off:"$PATH"

cd $SYMRUSTC_LIBAFL_SOLVING_DIR
cargo make test
