#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

dir=target_cargo_on/symrustc/run/output_log

function symrustc () {
    local pat="$1"; shift
    
    rm -rf target_cargo_on
    $SYMRUSTC_HOME_RS/symrustc_build.sh
    mkdir -p $dir
    $SYMRUSTC_HOME_RS/symrustc_run.sh test 2>&1 | tee $dir/output
    pushd "$dir"
    csplit -n 4 -f output_split output '/_sym_push_path_constraint /' '{*}'
    mv -i output ../output_log_full
    grep "$pat" * > ../output_log_full0
    cut -d ':' -f 1 ../output_log_full0 > ../output_log_full0_pat
    popd
}

#

dir_out2=target_cargo_on_qsym
symrustc 'New testcase'
mv -i target_cargo_on $dir_out2

dir_out1=target_cargo_on_simple_z3
SYMRUSTC_RUNTIME_DIR=/home/ubuntu/symcc_build_simple/SymRuntime-prefix/src/SymRuntime-build \
  symrustc 'diverging input'
mv -i target_cargo_on $dir_out1

#

grep -f $dir_out2/symrustc/run/output_log_full0_pat $dir_out1/symrustc/run/output_log_full0 > $dir_out1/symrustc/run/output_log_full0_subset
