#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

cat > libsancov.cpp <<EOF
#include <stdint.h>

extern "C" void __sanitizer_cov_trace_pc_guard_init(uint32_t *,
                                                    uint32_t *) {
  return;
}

extern "C" void __sanitizer_cov_trace_pc_guard(uint32_t *) {
  return;
}
EOF

export PATH=$SYMRUSTC_USER/clang_symcc_off:"$PATH"

clang++ -c -o libsancov.o libsancov.cpp
clang++ -shared -o libsancov.so libsancov.o

cargo make test
