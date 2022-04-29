#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source $SYMRUSTC_HOME_RS/parse_args0.sh

rustc_input_file="$1"; shift

target="$SYMRUSTC_DIR/$CARGO_TARGET_DIR"
target_d="$target/debug"
target_d_d="$target_d/deps"

#

export SYMCC_OUTPUT_DIR="$target/$SYMRUSTC_TARGET_NAME/output"

mkdir -p "$target_d_d" \
         "$SYMCC_OUTPUT_DIR"

#

metadata=b4b070263fc6e28b
rustc_exit_code=0

CARGO=$SYMRUSTC_CARGO \
CARGO_BIN_NAME=belcarra \
CARGO_CRATE_NAME=belcarra \
CARGO_MANIFEST_DIR="$SYMRUSTC_DIR" \
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
LD_LIBRARY_PATH="$target_d_d:$SYMRUSTC_LD_LIBRARY_PATH" \
\
$SYMRUSTC_RUSTC \
  --crate-name belcarra \
  --edition=2018 \
  "$rustc_input_file" \
  --error-format=json \
  --json=diagnostic-rendered-ansi \
  --crate-type bin \
  --emit=dep-info,link \
  -C embed-bitcode=no \
  -C debuginfo=2 \
  -C metadata=$metadata \
  -C extra-filename=-$metadata \
  --out-dir "$target_d_d" \
  -C incremental="$target_d/incremental" \
  -L dependency="$target_d_d" \
  -L$SYMRUSTC_RUNTIME_DIR \
  -Clink-arg=-Wl,-rpath,$SYMRUSTC_RUNTIME_DIR \
  "$@" \
|| rustc_exit_code=$?

ln -s "$target_d_d/belcarra-$metadata" "$target_d/belcarra"

$SYMRUSTC_HOME_RS/hexdump.sh $SYMRUSTC_INPUT_FILE

if [[ ! -v SYMRUSTC_SKIP_FAIL ]] ; then
    exit $rustc_exit_code
else
    echo "$target: rustc exit code: $rustc_exit_code" >&2
fi
