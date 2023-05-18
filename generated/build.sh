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

# Set up Ubuntu/Rust environment
docker_b base_rust

# Build LibAFL solving runtime
docker_b libafl_solving

# Build LibAFL solving runtime main
docker_b libafl_solving_main

# Build end user environment
docker_b end_user

# Build concolic Rust examples for LibAFL solving
docker_b libafl_solving_example

# Build cargo-fuzz
docker_b cargo_fuzz

# Build concolic Rust examples - set up project source - local example - fuzz
docker_b examples_rs_source_local_fuzz

# Build end user environment main
docker_b end_user_main

