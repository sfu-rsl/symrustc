#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

if eval $SYMRUSTC_BUILD_COMP_CONCOLIC; then
    for target0 in target_rustc_none target_rustc_file target_rustc_stdin
    do
        for target_pass in on off
        do
            target=$SYMRUSTC_EXAMPLE/${target0}_$target_pass
            ls $target/$SYMRUSTC_TARGET_NAME/output | wc -l
            cat $target/$SYMRUSTC_TARGET_NAME/hexdump_stdout
            cat $target/$SYMRUSTC_TARGET_NAME/hexdump_stderr
        done
    done
fi
