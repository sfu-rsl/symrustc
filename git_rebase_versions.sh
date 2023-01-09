#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

remote="$(git remote)"

function echo_read () {
    set +x
    echo -n "$1"
    read
    set -x
}

function generate () {
    ./make_build.sh
    git add .github/workflows/build.yml generated/build.sh
    git commit --fixup HEAD
    git rebase -i --autosquash --autostash HEAD~2
}

function git_rebase_push () {
    local br1=$1; shift
    local br2=$1; shift
    local count=$1; shift

    err=0
    git rebase --onto ${br1} ${br2}~${count} ${br2} || err=$?
    if (( err )); then
        echo_read "Error: rebase ($err). Conflict resolved? If yes, continue? "
    fi
    if [[ -v SYMRUSTC_GENERATE ]] || [[ -v SYMRUSTC_GENERATE_INTERACTIVE ]] ; then
        git checkout ${br2}
        if [[ -v SYMRUSTC_GENERATE_INTERACTIVE ]] ; then
            if zenity --info --title 'bool' --text "${br2}: update the generated files?" ; then
                generate
            fi
        else
            generate
        fi
    fi
    
    git push --force-with-lease "$remote" ${br2}
}

declare -a git_count=()

version0=1.46.0
version1a=no_insert/1.55.0
version2a=rust_runtime/1.55.0
version1b=no_insert/1.62.1
version2b=extended_examples/1.62.1
version1c=no_insert/1.63.0
version2c=extended_examples/1.63.0
versions=( ubuntu_20_04/1.47.0 \
           1.47.0 \
           no_insert/1.48.0 \
           no_insert/1.49.0 \
           no_insert/1.50.0 \
           no_insert/1.51.0 \
           no_insert/1.52.1 \
           no_insert/1.53.0 \
           no_insert/1.54.0 \
           $version1a \
           no_insert/1.56.1 \
           no_insert/1.57.0 \
           no_insert/1.58.1 \
           no_insert/1.59.0 \
           no_insert/1.60.0 \
           no_insert/1.61.0 \
           $version1b \
           $version1c \
           no_insert/1.64.0 \
           no_insert/ubuntu_20_10/1.64.0 \
           no_insert/1.65.0 \
           no_insert/1.66.0 )

#

git_count+=("$(git rev-list --count ^"$remote/$version0" "$remote/full_runtime/1.46.0")")
git_count+=("$(git rev-list --count ^"$remote/$version0" "$remote/verbose/1.46.0")")

br1=$version0
for br2 in "${versions[@]}"
do
    git_count+=("$(git rev-list --count ^"$remote/$br1" "$remote/$br2")")
    br1=${br2}
done
git_count+=("$(git rev-list --count ^"$remote/$version1a" "$remote/$version2a")")
git_count+=("$(git rev-list --count ^"$remote/$version1b" "$remote/$version2b")")
git_count+=("$(git rev-list --count ^"$remote/$version1c" "$remote/$version2c")")

#

git push --force-with-lease "$remote" $version0

#

git_rebase_push $version0 full_runtime/1.46.0 "${git_count[0]}"; git_count=("${git_count[@]:1}")
git_rebase_push $version0 verbose/1.46.0 "${git_count[0]}"; git_count=("${git_count[@]:1}")

br1=$version0
for br2 in "${versions[@]}"
do
    git_rebase_push $br1 $br2 "${git_count[0]}"; git_count=("${git_count[@]:1}")
    br1=${br2}
done
git_rebase_push $version1a $version2a "${git_count[0]}"; git_count=("${git_count[@]:1}")
git_rebase_push $version1b $version2b "${git_count[0]}"; git_count=("${git_count[@]:1}")
git_rebase_push $version1c $version2c "${git_count[0]}"; git_count=("${git_count[@]:1}")

#

git checkout $version0
