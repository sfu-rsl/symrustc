#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

err=0
hash="$(git log -1 --pretty=format:%H)" || err="$?"

if (( "$err" )); then
    if (( $# >= 1 )) ; then
        SYMRUSTC_BRANCH="$1"; shift
    else
        exit "$err"
    fi
else
    SYMRUSTC_BRANCH="$(git branch --contains "$hash" | grep '*' | cut -d ' ' -f 2-)"
fi
