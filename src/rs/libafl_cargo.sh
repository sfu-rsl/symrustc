#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

cargo rustc --release --package belcarra --lib -- -C llvm-args=--sanitizer-coverage-level=3 -C passes=sancov-module

cp -p target/release/deps/*rlib ../target/release/deps

cargo rustc --release --target-dir ../target

ls target/release/deps/*rlib | while read i ; do
    cmp "$i" "../$i" >&2 || (echo 'cargo recompiled the copied rlib' >&2 ; exit 1)
done
