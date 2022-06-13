#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

source $SYMRUSTC_HOME_RS/parse_args.sh

source $SYMRUSTC_HOME_RS/wait_all.sh

exec $SYMRUSTC_HOME_RS/env0.sh "$@"
