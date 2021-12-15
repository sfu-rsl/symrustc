#!/bin/bash

set -euxo pipefail

export SYMCC_LIBCXX_PATH=/libcxx_symcc_install
./build_exec_sym++_simple_z3.sh
