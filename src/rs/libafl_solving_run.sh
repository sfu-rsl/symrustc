#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

if [[ -z "${SYMRUSTC_LOG_PREFIX:-}" ]] ; then
    SYMRUSTC_LOG_PREFIX="$PWD"/
fi

if [[ -v SYMRUSTC_LIBAFL_CONCOLIC ]] ; then
    SYMRUSTC_LOG_PREFIX="${SYMRUSTC_LOG_PREFIX}_symrustc"
else
    SYMRUSTC_LOG_PREFIX="${SYMRUSTC_LOG_PREFIX}_libafl_fuzz"
fi

export SYMRUSTC_LOG_PREFIX

$SYMRUSTC_HOME_RS/libafl_solving_run0.sh "$@"
