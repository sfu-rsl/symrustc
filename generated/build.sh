#!/bin/bash

set -euxo pipefail

# Set up Ubuntu environment
docker build --target builder_base -t belcarra_base .

# Set up project source
docker build --target builder_source -t belcarra_source .

# Set up project dependencies
docker build --target builder_depend -t belcarra_depend .

# Build AFL
docker build --target builder_afl -t belcarra_afl .

# Build SymCC simple backend
docker build --target builder_symcc_simple -t belcarra_symcc_simple .

# Build LLVM libcxx using SymCC simple backend
docker build --target builder_symcc_libcxx -t belcarra_symcc_libcxx .

# Build SymCC Qsym backend
docker build --target builder_symcc_qsym -t belcarra_symcc_qsym .

# Build Rust compiler with SymCC support
docker build --target builder_rust -t belcarra_rust .

# Build additional tools
docker build --target builder_addons -t belcarra_addons .

# Create main image
docker build --target builder_main -t belcarra_main .

# Create final image
docker build --target builder_final -t belcarra_final .

# Build concolic C++ examples - SymCC/Z3, libcxx regular
docker build --target builder_examples_cpp_z3_libcxx_reg -t belcarra_examples_cpp_z3_libcxx_reg .

# Build concolic C++ examples - SymCC/Z3, libcxx instrumented
docker build --target builder_examples_cpp_z3_libcxx_inst -t belcarra_examples_cpp_z3_libcxx_inst .

# Build concolic C++ examples - SymCC/QSYM
docker build --target builder_examples_cpp_qsym -t belcarra_examples_cpp_qsym .

# Build concolic C++ examples - Only clang
docker build --target builder_examples_cpp_clang -t belcarra_examples_cpp_clang .

# Build concolic Rust examples
docker build --target builder_examples_rs -t belcarra_examples_rs .

