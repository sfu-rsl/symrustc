#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source git_current_branch.sh

name="$(basename $PWD)_log_${hash}__"

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

sudo ./build_all_sudo.sh "$SYMRUSTC_BRANCH" "$SYMRUSTC_DIR_COPY" 2>&1 | tee_log
sudo docker tag belcarra_end_user ghcr.io/sfu-rsl/symrustc_hybrid:latest
if [[ -v SYMRUSTC_DOCKER_PUSH ]] ; then
    # echo $TOKEN_GHCR | sudo docker login ghcr.io -u $USER --password-stdin
    sudo docker push ghcr.io/sfu-rsl/symrustc_hybrid:latest
fi
