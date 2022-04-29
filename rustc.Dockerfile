# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)


#
# Build Rust compiler
#
ARG RUST_SOURCE
FROM $RUST_SOURCE

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
    && sudo apt-get clean

RUN cd rust_source \
    && /usr/bin/python3 ./x.py build

ARG SYMRUSTC_RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
ARG SYMRUSTC_RUST_BUILD_STAGE=$SYMRUSTC_RUST_BUILD/stage1

ENV SYMRUSTC_CARGO=$SYMRUSTC_RUST_BUILD/stage0/bin/cargo
ENV SYMRUSTC_RUSTC=$SYMRUSTC_RUST_BUILD_STAGE/bin/rustc
ENV SYMRUSTC_LD_LIBRARY_PATH=$SYMRUSTC_RUST_BUILD_STAGE/lib
ENV PATH=$HOME/.cargo/bin:$PATH

