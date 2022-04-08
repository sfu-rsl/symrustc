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
# The base image
#
FROM ubuntu:20.04 AS builder_base

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo

RUN useradd -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu

USER ubuntu
ENV HOME /home/ubuntu
WORKDIR $HOME


#
# Prepare project source
#
FROM builder_base AS builder_source

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-10 \
        cmake \
        g++ \
        git \
        libz3-dev \
        ninja-build \
        python3-pip

RUN mkdir belcarra_source
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

# Download the Rust compiler with SymCC
RUN git clone -b symcc_comp_utils/1.46.0 --depth 1 https://github.com/sfu-rsl/rust.git rust_source

# Init submodules
RUN if git -C rust_source submodule status | grep "^-">/dev/null ; then \
    git -C rust_source submodule update --init --recursive; \
    fi

#
RUN ln -s ~/rust_source/src/llvm-project llvm_source
RUN ln -s ~/llvm_source/symcc symcc_source

# Note: Ideally, all submodules must also follow the change of version happening in the super-root project.
RUN cd symcc_source \
    && git checkout -b submodule \
    && git checkout -b main origin/main/10.0-2020-05-05 \
    && cp -a . ~/symcc_source_main \
    && git checkout submodule


#
# Prepare project dependencies
#
FROM builder_source AS builder_depend

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        llvm-10-dev \
        llvm-10-tools \
        python2 \
        zlib1g-dev
RUN pip3 install lit
ENV PATH $HOME/.local/bin:$PATH

# Build AFL.
RUN git clone -b v2.56b https://github.com/google/AFL.git afl \
    && cd afl \
    && make


#
# Build SymCC with the simple backend
#
FROM builder_depend AS builder_simple
RUN mkdir symcc_build_simple \
    && cd symcc_build_simple \
    && cmake -G Ninja ~/symcc_source_main \
        -DLLVM_VERSION_FORCE=10 \
        -DQSYM_BACKEND=OFF \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
    && ninja check


#
# Build libc++ with SymCC using the simple backend
#
FROM builder_simple AS builder_libcxx
RUN export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
  && mkdir -p rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && cd rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && cmake -G Ninja ~/llvm_source/llvm \
  -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_DISTRIBUTION_COMPONENTS="cxx;cxxabi;cxx-headers" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=~/libcxx_symcc_install \
  -DCMAKE_C_COMPILER=$HOME/symcc_build_simple/symcc \
  -DCMAKE_CXX_COMPILER=$HOME/symcc_build_simple/sym++ \
  && ninja distribution \
  && ninja install-distribution


#
# Build SymCC with the Qsym backend
#
FROM builder_libcxx AS builder_qsym
RUN mkdir symcc_build \
    && cd symcc_build \
    && cmake -G Ninja ~/symcc_source_main \
        -DLLVM_VERSION_FORCE=10 \
        -DQSYM_BACKEND=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
    && ninja check


#
# Build Rust compiler with SymCC support
#
FROM builder_source AS builder_rust

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl

COPY --chown=ubuntu:ubuntu --from=builder_qsym $HOME/symcc_build symcc_build

RUN export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd rust_source \
    && sed -e 's/#ninja = false/ninja = true/' \
        config.toml.example > config.toml \
    && export SYMCC_RUNTIME_DIR=$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
    && /usr/bin/python3 ./x.py build


#
# Build SymCC additional tools
#
FROM builder_rust AS builder_addons

RUN export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd symcc_build \
    && SYMCC_RUNTIME_DIR=$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
       RUSTFLAGS="-L${SYMCC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMCC_RUNTIME_DIR} -C passes=symcc -lSymRuntime" \
       RUSTC=~/rust_source/build/x86_64-unknown-linux-gnu/stage2/bin/rustc \
       ~/rust_source/build/x86_64-unknown-linux-gnu/stage0/bin/cargo install --path ~/symcc_source/util/symcc_fuzzing_helper
ENV PATH $HOME/.cargo/bin:$PATH


#
# The final image
#
FROM builder_addons as builder_final

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        libllvm10 \
        zlib1g

RUN ln -s ~/symcc_source/util/pure_concolic_execution.sh symcc_build
COPY --chown=ubuntu:ubuntu --from=builder_qsym $HOME/libcxx_symcc_install libcxx_symcc_install
COPY --chown=ubuntu:ubuntu --from=builder_qsym $HOME/afl afl
RUN mkdir symcc_build_clang \
    && ln -s ~/symcc_build/symcc symcc_build_clang/clang \
    && ln -s ~/symcc_build/sym++ symcc_build_clang/clang++

ENV PATH $HOME/symcc_build_clang:$HOME/symcc_build:$PATH
ENV AFL_PATH $HOME/afl
ENV AFL_CC clang-10
ENV AFL_CXX clang++-10
ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install

RUN mkdir /tmp/output


#
# Building C++ examples
#
FROM builder_final AS builder_examples_cpp

RUN cd belcarra_source/examples \
    && ./build_docker2.sh


#
# Building Rust examples
#
FROM builder_final AS builder_examples_rs

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bsdmainutils

ARG RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
ARG BELCARRA_EXAMPLE=$HOME/belcarra_source/examples/source_0_original_1b_rs
ARG BELCARRA_INPUT=test
ARG HEXDUMP="hexdump -v -C"

RUN export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd $BELCARRA_EXAMPLE \
    && SYMCC_RUNTIME_DIR=$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
       RUSTFLAGS="-L${SYMCC_RUNTIME_DIR} -Clink-arg=-Wl,-rpath,${SYMCC_RUNTIME_DIR} -C passes=symcc -lSymRuntime" \
       RUSTC=$RUST_BUILD/stage2/bin/rustc \
       $RUST_BUILD/stage0/bin/cargo rustc

RUN cd $BELCARRA_EXAMPLE \
    && echo $BELCARRA_INPUT | ./target/debug/belcarra \
    && echo $BELCARRA_INPUT | $HEXDUMP /dev/stdin > /tmp/belcarra_stdin_hex

SHELL ["/bin/bash", "-c"]
RUN ls /tmp/output/* | while read i ; \
    do echo -e "=============================\n$i" ; \
       $HEXDUMP "$i" | (git diff --color-words --no-index /tmp/belcarra_stdin_hex - || true) | tail -n +5 ; \
    done
