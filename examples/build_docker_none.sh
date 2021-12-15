#!/bin/bash

set -euxo pipefail

./build_llvm_clang++.sh
./build_exec_clang++.sh
