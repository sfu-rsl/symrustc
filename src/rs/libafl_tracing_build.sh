#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

source $SYMRUSTC_HOME_RS/parse_args.sh

#

pushd $SYMRUSTC_LIBAFL_TRACING_DIR >/dev/null

declare -i err=0
../../target/debug/dump_constraints --plain-text --output output_build.txt -- \
    $SYMRUSTC_HOME_RS/symrustc_build.sh \
|| err=$?

popd >/dev/null

if [[ -v SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_TRACING ]] ; then
    if ((err != 0)); then
        echo "error exit code: $err" >&2
    fi
else
    exit $err
fi
