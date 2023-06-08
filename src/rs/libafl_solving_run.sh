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

date_now="$(date '+%F_%T' | tr -d ':-')"

log_server_grep=log_server
log_server="$HOME/libafl_${date_now}_server"
log_client1="$HOME/libafl_${date_now}_client1"
log_client2="$HOME/libafl_${date_now}_client2"

pushd $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer >/dev/null

mkdir -p corpus
fic_corpus="corpus/${date_now}"
echo "$@" > $fic_corpus

ln -s $(find -L $SYMRUSTC_DIR/target_cargo_on/debug -maxdepth 1 -type f -executable | grep . -m 1) target_symcc.out

fuzz_bin=$(find -L target/release -maxdepth 1 -type f -executable | grep . -m 1)

fuzz_bin_fic=./fuzz_bin.sh

cat > $fuzz_bin_fic <<"EOF"
#!/bin/bash
set -euo pipefail

echo "$(date): $$ start" >&2
exit_code=0
EOF
cat >> $fuzz_bin_fic <<EOF
$fuzz_bin "\$@" || exit_code=\$?
EOF
cat >> $fuzz_bin_fic <<"EOF"
echo "$(date): $$ exit code: $exit_code" >&2
exit $exit_code
EOF

chmod +x $fuzz_bin_fic

readlink -e harness > $log_server

# starting the server
if [[ -v SYMRUSTC_LIBAFL_SOLVING_OBJECTIVE ]] ; then
    mkfifo $log_server_grep
    $fuzz_bin_fic | tee -a $log_server | tee $log_server_grep &
else
    $fuzz_bin_fic | tee -a $log_server &
fi

# waiting for the server to listen to new clients
while ! nc -zv localhost 1337 ; do
    sleep 1
done

# starting the clients
$fuzz_bin_fic --concolic >$log_client1 2>&1 &
proc_client1=$!
$fuzz_bin_fic >$log_client2 2>&1 &
proc_client2=$!

# waiting
if [[ -v SYMRUSTC_LIBAFL_SOLVING_OBJECTIVE ]] ; then
    # waiting for a specific message from the server before proceeding further
    grep -q 'objectives: 2' $log_server_grep
else
    echo "Only executing during a finite period of time, irrespective of objective search" >&2
    sleep 300
fi

# terminating the client first, then any remaining forked processes not yet terminated
kill $proc_client1 || echo "error (client1): kill ($?)" >&2
wait $proc_client1 || echo "error (client1): wait ($?)" >&2
kill $proc_client2 || echo "error (client2): kill ($?)" >&2
wait $proc_client2 || echo "error (client2): wait ($?)" >&2
killall $fuzz_bin || echo "error: killall ($?)" >&2
wait_all

# cleaning
if [[ -v SYMRUSTC_LIBAFL_SOLVING_OBJECTIVE ]] ; then
    rm $log_server_grep
fi
rm $fic_corpus
rm $fuzz_bin_fic
rm target_symcc.out

popd >/dev/null

#

rm -rf /tmp/output
swap
