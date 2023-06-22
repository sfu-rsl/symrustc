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

if [[ ! -v SYMRUSTC_DIR_COPY ]] ; then
    SYMRUSTC_DIR_COPY=examples
else
    SYMRUSTC_DIR_COPY="$(realpath -e "$SYMRUSTC_DIR_COPY")"
    if [[ ! -d "$SYMRUSTC_DIR_COPY" ]] ; then
        echo "Error: Expecting a directory" >&2
        exit 1
    fi
    SYMRUSTC_DIR_COPY="$(echo "${SYMRUSTC_DIR_COPY#"$(pwd -P)/"}" | cut -d '/' -f 1)"
    if [[ -z "$SYMRUSTC_DIR_COPY" ]] ; then
        echo "Warning: Expecting a local directory" >&2
        SYMRUSTC_DIR_COPY=examples
    fi
fi

# https://github.com/project-oak/rust-verification-tools/pull/140
function sudo_docker_if_needed () {
    fic=/var/run/docker.sock
    if [[ -w $fic ]] ; then
        docker "$@"
    else
        echo "Running docker with sudo for writing to $fic" >&2
        echo 'See also the security implications of adding someone to the docker group:' >&2
        echo 'https://docs.docker.com/engine/security/#docker-daemon-attack-surface' >&2
        # https://docs.docker.com/engine/install/linux-postinstall/
        sudo docker "$@"
    fi
}
export -f sudo_docker_if_needed
