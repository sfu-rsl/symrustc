# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

# #

# This file is part of SymCC.
#
# SymCC is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# SymCC is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# SymCC. If not, see <https://www.gnu.org/licenses/>.

# #

#
# Set up Ubuntu environment
#
FROM ubuntu:20.04 AS builder_base

SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo \
    && apt-get clean

RUN useradd -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu

USER ubuntu
ENV HOME=/home/ubuntu
WORKDIR $HOME


#
# Set up project source
#
FROM builder_base AS builder_source

ENV SYMRUSTC_LLVM_VERSION=10

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cmake \
        git \
        libz3-dev \
        ninja-build \
        python3-pip \
    && sudo apt-get clean

ENV SYMRUSTC_HOME=$HOME/belcarra_source
ENV SYMRUSTC_HOME_CPP=$SYMRUSTC_HOME/src/cpp
ENV SYMRUSTC_HOME_RS=$SYMRUSTC_HOME/src/rs
ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install

#
RUN ln -s ~/rust_source/src/llvm-project llvm_source
RUN ln -s ~/llvm_source/symcc symcc_source

COPY --chown=ubuntu:ubuntu rust_source.tar rust_source.tar
RUN tar xf rust_source.tar \
    && rm rust_source.tar


#
# Set up project dependencies
#
FROM builder_source AS builder_depend

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python2 \
        zlib1g-dev \
    && sudo apt-get clean
RUN pip3 install lit
ENV PATH=$HOME/.local/bin:$PATH


#
# Build SymLLVM
#
FROM builder_depend AS builder_symllvm

COPY --chown=ubuntu:ubuntu src/llvm/cmake.sh $SYMRUSTC_HOME/src/llvm/

RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && cd -P rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && $SYMRUSTC_HOME/src/llvm/cmake.sh


#
# Build SymRustC core
#
FROM builder_source AS builder_symrustc

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
    && sudo apt-get clean

#

COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/symcc_build_simple symcc_build_simple
COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/symcc_build symcc_build

RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu
COPY --chown=ubuntu:ubuntu --from=builder_symllvm $HOME/rust_source/build/x86_64-unknown-linux-gnu/llvm rust_source/build/x86_64-unknown-linux-gnu/llvm

#

ENV SYMRUSTC_RUNTIME_DIR=$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build

RUN export SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd rust_source \
    && sed -e 's/#ninja = false/ninja = true/' \
        config.toml.example > config.toml \
    && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
        src/librustc_span/analyze_source_file.rs \
    && export SYMCC_RUNTIME_DIR=$SYMRUSTC_RUNTIME_DIR \
    && /usr/bin/python3 ./x.py build

#

ARG SYMRUSTC_RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
ARG SYMRUSTC_RUST_BUILD_STAGE=$SYMRUSTC_RUST_BUILD/stage2

ENV SYMRUSTC_CARGO=$SYMRUSTC_RUST_BUILD/stage0/bin/cargo
ENV SYMRUSTC_RUSTC=$SYMRUSTC_RUST_BUILD_STAGE/bin/rustc
ENV SYMRUSTC_LD_LIBRARY_PATH=$SYMRUSTC_RUST_BUILD_STAGE/lib
ENV PATH=$HOME/.cargo/bin:$PATH

COPY --chown=ubuntu:ubuntu --from=builder_symcc_libcxx $SYMCC_LIBCXX_PATH $SYMCC_LIBCXX_PATH

RUN mkdir clang_symcc_on \
    && ln -s ~/symcc_build/symcc clang_symcc_on/clang \
    && ln -s ~/symcc_build/sym++ clang_symcc_on/clang++

RUN mkdir clang_symcc_off \
    && ln -s $(which clang-$SYMRUSTC_LLVM_VERSION) clang_symcc_off/clang \
    && ln -s $(which clang++-$SYMRUSTC_LLVM_VERSION) clang_symcc_off/clang++


#
# Build SymRustC main
#
FROM builder_symrustc AS builder_symrustc_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bsdmainutils \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu src/rs belcarra_source/src/rs
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples


#
# Build concolic Rust examples
#
FROM builder_symrustc_main AS builder_examples_rs

ARG SYMRUSTC_CI

ARG SYMRUSTC_SKIP_FAIL

ARG SYMRUSTC_VERBOSE

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_RS/fold_symrustc_build.sh

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_RS/fold_symrustc_run.sh


#
# Build additional tools
#
FROM builder_symrustc AS builder_addons

ARG SYMRUSTC_CI

COPY --chown=ubuntu:ubuntu src/rs/env0.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/env.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/parse_args0.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/parse_args.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/wait_all.sh $SYMRUSTC_HOME_RS/

RUN cd ~/symcc_source/util/symcc_fuzzing_helper \
    && $SYMRUSTC_HOME_RS/env.sh $SYMRUSTC_CARGO install --path $PWD


#
# Build extended main
#
FROM builder_symrustc_main AS builder_extended_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        libllvm$SYMRUSTC_LLVM_VERSION \
        zlib1g \
    && sudo apt-get clean

RUN ln -s ~/symcc_source/util/pure_concolic_execution.sh symcc_build
COPY --chown=ubuntu:ubuntu --from=builder_afl $HOME/afl afl
COPY --chown=ubuntu:ubuntu --from=builder_addons $HOME/.cargo .cargo

ENV PATH=$HOME/symcc_build:$PATH

ENV AFL_PATH=$HOME/afl
ENV AFL_CC=clang-$SYMRUSTC_LLVM_VERSION
ENV AFL_CXX=clang++-$SYMRUSTC_LLVM_VERSION


#
# Build concolic C++ examples - SymCC/Z3, libcxx regular
#
FROM builder_symcc_simple AS builder_examples_cpp_z3_libcxx_reg

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && export SYMCC_REGULAR_LIBCXX=yes \
    && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh


#
# Build concolic C++ examples - SymCC/Z3, libcxx instrumented
#
FROM builder_symcc_libcxx AS builder_examples_cpp_z3_libcxx_inst

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh


#
# Build concolic C++ examples - SymCC/QSYM
#
FROM builder_symcc_qsym AS builder_examples_cpp_qsym

RUN mkdir /tmp/output

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_CPP/main_fold_sym++_qsym.sh


#
# Build concolic C++ examples - Only clang
#
FROM builder_source AS builder_examples_cpp_clang

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_CPP/main_fold_clang++.sh
