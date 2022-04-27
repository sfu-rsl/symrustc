#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

if [ -v BELCARRA_CI ]; then
    function fork () {
        "$@"
    }
else
    function fork () {
        "$@" &
    }
fi

# https://stackoverflow.com/a/71778264
function wait_all () {
    declare -i err=0 werr=0
    
    while wait -fn || werr=$?; ((werr != 127)); do
        err=$werr
    done

    if ((err != 0)); then
        exit $err
    fi
}
