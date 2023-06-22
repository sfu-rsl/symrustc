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

./build_all_sudo.sh "$SYMRUSTC_BRANCH" "$SYMRUSTC_DIR_COPY"
sudo_docker_if_needed tag belcarra_end_user ghcr.io/sfu-rsl/symrustc_hybrid:latest
if [[ -v SYMRUSTC_DOCKER_PUSH ]] ; then
    # echo $TOKEN_GHCR | sudo_if_needed docker login ghcr.io -u $USER --password-stdin
    sudo_docker_if_needed push ghcr.io/sfu-rsl/symrustc_hybrid:latest
fi
sudo_docker_if_needed run -it --rm belcarra_$(tac generated/build.sh | grep -m 1 docker | tr ' ' '\n' | tail -n 1)
