#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

dir_rustc=$RUST_BUILD/stage2
dir_prog=$(pwd)
input_file=$dir_prog/src/main.rs

#

mkdir -p target/debug/deps

export SYMCC_INPUT_FILE=$input_file

rustc_exit_code=0

CARGO=$RUST_BUILD/stage0/bin/cargo \
CARGO_BIN_NAME=belcarra \
CARGO_CRATE_NAME=belcarra \
CARGO_MANIFEST_DIR=$dir_prog \
CARGO_PKG_AUTHORS='' \
CARGO_PKG_DESCRIPTION='' \
CARGO_PKG_HOMEPAGE='' \
CARGO_PKG_LICENSE='' \
CARGO_PKG_LICENSE_FILE='' \
CARGO_PKG_NAME=belcarra \
CARGO_PKG_REPOSITORY='' \
CARGO_PKG_VERSION=0.1.0 \
CARGO_PKG_VERSION_MAJOR=0 \
CARGO_PKG_VERSION_MINOR=1 \
CARGO_PKG_VERSION_PATCH=0 \
CARGO_PKG_VERSION_PRE='' \
CARGO_PRIMARY_PACKAGE=1 \
LD_LIBRARY_PATH="$dir_prog/target/debug/deps:$dir_rustc/lib::$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build" \
\
$dir_rustc/bin/rustc \
  --crate-name belcarra \
  --edition=2018 \
  $input_file \
  --error-format=json \
  --json=diagnostic-rendered-ansi \
  --crate-type bin \
  --emit=dep-info,link \
  -C embed-bitcode=no \
  -C debuginfo=2 \
  -C metadata=fdf6308bae5a5c1e \
  -C extra-filename=-fdf6308bae5a5c1e \
  --out-dir $dir_prog/target/debug/deps \
  -C incremental=$dir_prog/target/debug/incremental \
  -L dependency=$dir_prog/target/debug/deps \
  -L$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
  -Clink-arg=-Wl,-rpath,$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
  "$@" \
|| rustc_exit_code=$?

#

set +x

HEXDUMP="hexdump -v -C"

$HEXDUMP $input_file > /tmp/belcarra_stdin_hex

ls /tmp/output/* | while read i
do
    echo -e "=============================\n$i"
    $HEXDUMP "$i" | (git diff --color-words --no-index /tmp/belcarra_stdin_hex - || true) | tail -n +5
done

#

exit $rustc_exit_code
