#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

source $SYMRUSTC_HOME_RS/parse_args.sh
source $SYMRUSTC_HOME_RS/wait_all.sh

# Building the client-server main fuzzing loop completely sanitized (example instrumented with libsancov)

$SYMRUSTC_HOME_RS/libafl_solving_build0.sh &

# Building the example with SymRustC (example instrumented with SymCC)

if [[ -v SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_SOLVING ]] ; then
    cd -P $SYMRUSTC_DIR
    mkdir -p target_cargo_on/debug
    curl -LO 'https://github.com/sfu-rsl/symrustc/raw/1.46.0_binary/'"$(echo $PWD | rev | cut -d / -f 1-2 | rev)"'/belcarra'
    chmod +x belcarra
    mv belcarra target_cargo_on/debug
else
    $SYMRUSTC_HOME_RS/symrustc_build.sh "$@"
fi

#

wait_all
