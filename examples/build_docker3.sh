#!/bin/bash

set -euxo pipefail

./build_llvm_ko-clang++.sh
./build_exec_ko-clang++.sh
