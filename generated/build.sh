#!/bin/bash

set -euxo pipefail

# Set up Ubuntu environment
docker_b base

# Set up project source
docker_b source

# Set up project dependencies
docker_b depend

# Build AFL
docker_b afl

# Build SymCC simple backend
docker_b symcc_simple

# Build LLVM libcxx using SymCC simple backend
docker_b symcc_libcxx

# Build SymCC Qsym backend
docker_b symcc_qsym

# Build SymLLVM
docker_b symllvm

# Build SymRustC core
docker_b symrustc

# Build SymRustC main
docker_b symrustc_main

# Build concolic Rust examples
docker_b examples_rs

# Build additional tools
docker_b addons

# Build extended main
docker_b extended_main

# Build concolic C++ examples - SymCC/Z3, libcxx regular
docker_b examples_cpp_z3_libcxx_reg

# Build concolic C++ examples - SymCC/Z3, libcxx instrumented
docker_b examples_cpp_z3_libcxx_inst

# Build concolic C++ examples - SymCC/QSYM
docker_b examples_cpp_qsym

# Build concolic C++ examples - Only clang
docker_b examples_cpp_clang

