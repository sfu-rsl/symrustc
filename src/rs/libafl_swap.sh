#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

name="$(basename $SYMRUSTC_RUNTIME_DIR)"

function swap () {
    pushd $SYMRUSTC_RUNTIME_DIR/.. >/dev/null
    mv -i "${name}" "${name}1"
    mv -i "${name}0" "${name}"
    mv -i "${name}1" "${name}0"
    popd >/dev/null
}
