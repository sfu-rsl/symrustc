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

sudo_if_needed ./build_all_sudo.sh "$SYMRUSTC_BRANCH" "$SYMRUSTC_DIR_COPY" 2>&1 | tee_log
sudo_if_needed docker tag belcarra_end_user ghcr.io/sfu-rsl/symrustc_hybrid:latest
if [[ -v SYMRUSTC_DOCKER_PUSH ]] ; then
    # echo $TOKEN_GHCR | sudo_if_needed docker login ghcr.io -u $USER --password-stdin
    sudo_if_needed docker push ghcr.io/sfu-rsl/symrustc_hybrid:latest
fi
sudo_if_needed docker run -it --rm $(grep '\--->' "$fic" | tail -n 1 | cut -d ' ' -f 3)
