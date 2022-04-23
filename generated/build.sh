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

# Build SymRustC
docker_b symrustc

# Build additional tools
docker_b addons

# Build main image
docker_b main

# Build concolic C++ examples - SymCC/Z3, libcxx regular
docker_b examples_cpp_z3_libcxx_reg

# Build concolic C++ examples - SymCC/Z3, libcxx instrumented
docker_b examples_cpp_z3_libcxx_inst

# Build concolic C++ examples - SymCC/QSYM
docker_b examples_cpp_qsym

# Build concolic C++ examples - Only clang
docker_b examples_cpp_clang

# Build concolic Rust examples
docker_b examples_rs

