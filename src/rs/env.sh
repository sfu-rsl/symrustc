#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

if [[ -v SYMRUSTC_DIR ]] ; then
    export SYMRUSTC_EXAMPLE="$SYMRUSTC_DIR"
else
    export SYMRUSTC_EXAMPLE="$PWD"
fi

source $SYMRUSTC_HOME_RS/wait_all.sh

exec $SYMRUSTC_HOME_RS/env0.sh "$@"
