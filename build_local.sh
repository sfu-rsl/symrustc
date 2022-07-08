#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -x

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

if [[ ! -d rust_source ]] || [[ ! -d symcc_source_main ]] ; then
    exit 1
fi

set -e

tar cf rust_source.tar rust_source
mv -i rust_source ..

tar cf symcc_source_main.tar symcc_source_main
mv -i symcc_source_main ..

set +e

sudo ./build_local_sudo.sh "$SYMRUSTC_BRANCH" 2>&1 | tee_log

set -e

rm rust_source.tar
mv -i ../rust_source .

rm symcc_source_main.tar
mv -i ../symcc_source_main .
