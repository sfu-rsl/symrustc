#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

input_file1="$1"; shift
input_file2="$1"; shift

target_d=$BELCARRA_EXAMPLE/target/debug
target_d_d=$target_d/deps

#

mkdir -p $target_d_d

#

metadata=b4b070263fc6e28b
rustc_exit_code=0

CARGO=$BELCARRA_CARGO \
CARGO_MANIFEST_DIR=$BELCARRA_EXAMPLE \
CARGO_PKG_AUTHORS='' \
CARGO_PKG_DESCRIPTION='' \
CARGO_PKG_HOMEPAGE='' \
CARGO_PKG_NAME=belcarra \
CARGO_PKG_REPOSITORY='' \
CARGO_PKG_VERSION=0.1.0 \
CARGO_PKG_VERSION_MAJOR=0 \
CARGO_PKG_VERSION_MINOR=1 \
CARGO_PKG_VERSION_PATCH=0 \
CARGO_PKG_VERSION_PRE='' \
LD_LIBRARY_PATH="$target_d_d:$BELCARRA_LD_LIBRARY_PATH" \
\
$BELCARRA_RUSTC \
  --crate-name belcarra \
  --edition=2018 \
  "$input_file1" \
  --error-format=json \
  --json=diagnostic-rendered-ansi \
  --crate-type bin \
  --emit=dep-info,link \
  -C embed-bitcode=no \
  -C debuginfo=2 \
  -C metadata=$metadata \
  -C extra-filename=-$metadata \
  --out-dir $target_d_d \
  -C incremental=$target_d/incremental \
  -L dependency=$target_d_d \
  -L$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
  -Clink-arg=-Wl,-rpath,$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
  "$@" \
|| rustc_exit_code=$?

$BELCARRA_EXAMPLE/../hexdump.sh "$input_file2"

exit $rustc_exit_code
