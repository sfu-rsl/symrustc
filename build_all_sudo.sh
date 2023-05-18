#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

export SYMRUSTC_BRANCH="$1"; shift

unit=G
size=$(echo $(df -B"$unit" --output=avail $(docker info | grep 'Root' | cut -d ':' -f 2) | tail -n 1))

if (( $(echo "$size" | cut -d "$unit" -f 1) < 30 )) ; then
    echo "Error: too low remaining disk space: $size" >&2
    exit 1
fi

function docker_b0 () {
    date -R
    /usr/bin/time -v docker build "$@"
}
export -f docker_b0

#

function docker_b () {
    docker_b0 --target "builder_$1" -t "belcarra_$1" --build-arg SYMRUSTC_BRANCH="$SYMRUSTC_BRANCH" --build-arg SYMRUSTC_SKIP_FAIL=yes --build-arg SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_TRACING=yes .
}
export -f docker_b

./generated/build.sh

#

# function docker_b () {
#     docker_b0 "$@"
# }
# export -f docker_b

# ./build_rustc.sh
