#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source git_current_branch.sh

name="$(basename $PWD)_log_${hash}__"

fic="../$name$(date '+%F_%T' | tr -d ':-')"

function tee_log () {
    if [ ! -f "$fic" ] ; then
        tee "$fic"
        date -R >> "$fic"
    else
        exit 1
    fi
}

#

sudo ./build_all_sudo.sh "$SYMRUSTC_BRANCH" 2>&1 | tee_log
sudo docker run -it --rm $(grep '\--->' "$fic" | tail -n 1 | cut -d ' ' -f 3)
