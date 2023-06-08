#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

$SYMRUSTC_HOME_RS/symrustc_build.sh
$SYMRUSTC_HOME_RS/symrustc_run.sh "$@"
