#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

name="$(basename $PWD)_log_$(git log -1 --pretty=format:%H)__"

function tee_log () {
    fic="../$name$(date '+%F_%T' | tr -d ':-')"
    if [ ! -f "$fic" ] ; then
        tee "$fic"
        date -R >> "$fic"
    else
        exit 1
    fi
}

#

sudo ./build_all_sudo.sh 2>&1 | tee_log
