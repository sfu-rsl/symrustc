#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

tee_file=/tmp/belcarra_stdin

tee $tee_file | $BELCARRA_EXAMPLE/../exec_rustc.sh - $tee_file "$@"
