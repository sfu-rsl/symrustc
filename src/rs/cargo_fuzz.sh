#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

cargo fuzz run $(cargo fuzz list | head -n 1) &
proc_fuzz=$!

# waiting
sleep 300

# terminating the client
kill $proc_fuzz || echo "error: kill ($?)" >&2
wait $proc_fuzz || echo "error: wait ($?)" >&2
