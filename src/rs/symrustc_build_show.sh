#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

if eval $SYMRUSTC_BUILD_COMP_CONCOLIC; then
    function basename2 () {
        echo "$1" | rev | cut -d '/' -f 1-2 | rev
    }
    for target0 in target_rustc_none target_rustc_file target_rustc_stdin
    do
        for target_pass in on off
        do
            target="$SYMRUSTC_DIR/${target0}_$target_pass"
            echo "Total number of testcases: $(ls "$target/$SYMRUSTC_TARGET_NAME/output" | wc -l) in $(basename2 "$target")"
            cat "$target/$SYMRUSTC_TARGET_NAME/hexdump_stdout"
            cat "$target/$SYMRUSTC_TARGET_NAME/hexdump_stderr"
        done
    done >&2
fi
