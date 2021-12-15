#!/bin/bash

set -euxo pipefail

./build_llvm_sym++.sh
./build_exec_sym++_qsym.sh
