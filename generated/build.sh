#!/bin/bash

set -euxo pipefail

# Set up Ubuntu environment
docker_b base

# Set up project source
docker_b source

# Set up project dependencies
docker_b depend

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

# Set up Ubuntu/Rust environment
docker_b base_rust

# Build LibAFL tracing runtime
docker_b libafl_tracing

# Build LibAFL tracing runtime main
docker_b libafl_tracing_main

# Build concolic Rust examples for LibAFL tracing
docker_b libafl_tracing_example

# Build LibAFL solving runtime
docker_b libafl_solving

# Build LibAFL solving instance runtime
docker_b libafl_solving_inst

# Build LibAFL solving runtime main
docker_b libafl_solving_main

# Build LibAFL solving instance runtime main
docker_b libafl_solving_inst_main

# Build concolic Rust examples for LibAFL solving
docker_b libafl_solving_example

# Build concolic Rust examples for LibAFL solving instance
docker_b libafl_solving_inst_example

# Build LibAFL ex image runtime
docker_b libafl_ex_image

# Build LibAFL ex image runtime main
docker_b libafl_ex_image_main

# Build concolic Rust examples for LibAFL ex image
docker_b libafl_ex_image_example

# Build additional tools
docker_b addons

# Build concolic Rust examples - set up project source - coreutils
docker_b examples_rs_source_coreutils

# Build concolic Rust examples - set up project source - coreutils - libafl
docker_b examples_rs_source_coreutils_libafl

# Build concolic Rust examples - coreutils
docker_b examples_rs_coreutils

# Build concolic Rust examples - coreutils - libafl
docker_b examples_rs_coreutils_libafl

# Build concolic Rust examples - set up project source - linux
docker_b examples_rs_source_linux

# Build concolic Rust examples - linux
docker_b examples_rs_linux

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

