#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

sed -E \
    -e 's," "," \\\n  ",g' \
    -e 's,/home/ubuntu,$HOME,g' \
    -e 's,(DLLVM_PARALLEL_COMPILE_JOBS)=[[:digit:]]*,\1=$jobs,'
