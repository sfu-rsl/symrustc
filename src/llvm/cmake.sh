#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

jobs="$(python3 -c 'import os; print(len(os.sched_getaffinity(0)))')"

"cmake" \
  "$HOME/belcarra_source0/src/rs/rust_source/src/llvm-project/llvm" \
  "-G" \
  "Ninja" \
  "-DLLVM_ENABLE_ASSERTIONS=OFF" \
  "-DLLVM_ENABLE_PLUGINS=OFF" \
  "-DLLVM_TARGETS_TO_BUILD=AArch64;ARM;BPF;Hexagon;MSP430;Mips;NVPTX;PowerPC;RISCV;Sparc;SystemZ;WebAssembly;X86" \
  "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=AVR" \
  "-DLLVM_INCLUDE_EXAMPLES=OFF" \
  "-DLLVM_INCLUDE_DOCS=OFF" \
  "-DLLVM_INCLUDE_BENCHMARKS=OFF" \
  "-DLLVM_INCLUDE_TESTS=OFF" \
  "-DLLVM_ENABLE_TERMINFO=OFF" \
  "-DLLVM_ENABLE_LIBEDIT=OFF" \
  "-DLLVM_ENABLE_BINDINGS=OFF" \
  "-DLLVM_ENABLE_Z3_SOLVER=OFF" \
  "-DLLVM_PARALLEL_COMPILE_JOBS=$jobs" \
  "-DLLVM_TARGET_ARCH=x86_64" \
  "-DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-gnu" \
  "-DLLVM_ENABLE_ZLIB=ON" \
  "-DLLVM_ENABLE_LIBXML2=OFF" \
  "-DLLVM_VERSION_SUFFIX=-rust-dev" \
  "-DCMAKE_INSTALL_MESSAGE=LAZY" \
  "-DCMAKE_C_COMPILER=cc" \
  "-DCMAKE_CXX_COMPILER=c++" \
  "-DCMAKE_ASM_COMPILER=cc" \
  "-DCMAKE_C_FLAGS=-ffunction-sections -fdata-sections -fPIC -m64" \
  "-DCMAKE_CXX_FLAGS=-ffunction-sections -fdata-sections -fPIC -m64" \
  "-DCMAKE_INSTALL_PREFIX=$HOME/belcarra_source0/src/rs/rust_source/build/x86_64-unknown-linux-gnu/llvm" \
  "-DCMAKE_ASM_FLAGS= -ffunction-sections -fdata-sections -fPIC -m64" \
  "-DCMAKE_BUILD_TYPE=Release"

"cmake" "--build" "." "--target" "install" "--config" "Release" "--" "-j" "$jobs"
