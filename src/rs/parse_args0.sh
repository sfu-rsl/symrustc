#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

if [[ ! -v SYMRUSTC_VERBOSE ]] ; then
    export SYMRUSTC_VERBOSE=false
fi

if eval $SYMRUSTC_VERBOSE ; then
    set -x
fi
