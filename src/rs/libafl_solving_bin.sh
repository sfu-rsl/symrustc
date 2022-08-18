#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/libafl_swap.sh

swap
err=0
./target_symcc.out "$@" || err=$?
swap
exit $err
