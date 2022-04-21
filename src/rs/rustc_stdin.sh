#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

cat $BELCARRA_INPUT_FILE | $BELCARRA_HOME_RS/rustc.sh - "$@"
