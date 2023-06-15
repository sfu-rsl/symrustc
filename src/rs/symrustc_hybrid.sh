#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args.sh

#

pushd $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer >/dev/null

ln -s $SYMRUSTC_DIR harness

pushd $SYMRUSTC_DIR >/dev/null

$SYMRUSTC_HOME_RS/libafl_solving_build.sh

# pure fuzzing execution
if [[ -v SYMRUSTC_LIBAFL_PURE_FUZZING ]] ; then
$SYMRUSTC_HOME_RS/libafl_solving_run.sh "$@"
sleep 1 # forcing the date to change (for filenames relying on the date)
fi

# hybrid execution
export SYMRUSTC_LIBAFL_CONCOLIC=yes
$SYMRUSTC_HOME_RS/libafl_solving_run.sh "$@"

popd >/dev/null

rm harness

popd >/dev/null
