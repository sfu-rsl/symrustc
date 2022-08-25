#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

source $SYMRUSTC_HOME_RS/parse_args.sh
source $SYMRUSTC_HOME_RS/wait_all.sh
source $SYMRUSTC_HOME_RS/libafl_swap.sh

#

mkdir /tmp/output
swap

#

fic_server=log_server

pushd $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer >/dev/null

mkdir -p corpus
fic_corpus="corpus/$(date '+%F_%T' | tr -d ':-')"
echo "$@" > $fic_corpus

ln -s $(find -L $SYMRUSTC_DIR/target_cargo_on/debug -maxdepth 1 -type f -executable | grep . -m 1) target_symcc.out

fuzz_bin=$(find -L target/release -maxdepth 1 -type f -executable | grep . -m 1)

mkfifo $fic_server

# starting the server
$fuzz_bin | tee $fic_server &

# waiting for the server to listen to new clients
while ! nc -zv localhost 1337 ; do
    sleep 1
done

# starting the client
$fuzz_bin --concolic &
proc_client=$!

# waiting for a specific message from the server before proceeding further
grep -q 'objectives: 2' $fic_server

# terminating the client first, then any remaining forked processes not yet terminated
kill $proc_client || echo "error: kill ($?)" >&2
wait $proc_client || echo "error: wait ($?)" >&2
killall $fuzz_bin || echo "error: killall ($?)" >&2
wait_all

# cleaning
rm $fic_server
rm $fic_corpus
rm target_symcc.out

popd >/dev/null

#

rm -rf /tmp/output
swap
