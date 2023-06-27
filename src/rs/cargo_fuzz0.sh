#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

if [[ ! -v SYMRUSTC_TIMEOUT ]] ; then
    SYMRUSTC_TIMEOUT=$SYMRUSTC_TIMEOUT_DEFAULT
fi

echo "$(date): $$ start" >&2

exit_code=0
timeout --preserve-status $SYMRUSTC_TIMEOUT cargo fuzz run $(cargo fuzz list | head -n 1) || exit_code=$?

echo "$(date): $$ exit code: $exit_code" >&2
