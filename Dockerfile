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

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo \
    && apt-get clean

RUN useradd -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu

USER ubuntu
ENV HOME /home/ubuntu
WORKDIR $HOME


#
# Set up project source
#
FROM builder_base AS builder_source

ENV BELCARRA_LLVM_VERSION 10

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-$BELCARRA_LLVM_VERSION \
        cmake \
        g++ \
        git \
        libz3-dev \
        ninja-build \
        python3-pip \
    && sudo apt-get clean

RUN mkdir belcarra_source
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

# Download the Rust compiler with SymCC
ARG BELCARRA_RUST_VERSION
ENV BELCARRA_RUST_VERSION=${BELCARRA_RUST_VERSION:-symcc_comp_utils/1.46.0}
RUN git clone -b $BELCARRA_RUST_VERSION --depth 1 https://github.com/sfu-rsl/rust.git rust_source

# Init submodules
RUN if git -C rust_source submodule status | grep "^-">/dev/null ; then \
      git -C rust_source submodule update --init --recursive; \
    fi

#
RUN ln -s ~/rust_source/src/llvm-project llvm_source
RUN ln -s ~/llvm_source/symcc symcc_source

# Note: Depending on the commit revision, the Rust compiler source may not have yet a SymCC directory. In this docker stage, we treat such case as a "non-aborting failure" (subsequent stages may raise different errors).
RUN if [ -d symcc_source ] ; then \
      cd symcc_source \
      && current=$(git log -1 --pretty=format:%H) \
# Note: Ideally, all submodules must also follow the change of version happening in the super-root project.
      && git checkout origin/main/$(git branch -r --contains "$current" | tr '/' '\n' | tail -n 1) \
      && cp -a . ~/symcc_source_main \
      && git checkout "$current"; \
    fi


#
# Set up project dependencies
#
FROM builder_source AS builder_depend

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        llvm-$BELCARRA_LLVM_VERSION-dev \
        llvm-$BELCARRA_LLVM_VERSION-tools \
        python2 \
        zlib1g-dev \
    && sudo apt-get clean
RUN pip3 install lit
ENV PATH $HOME/.local/bin:$PATH

# Build AFL.
RUN git clone -b v2.56b https://github.com/google/AFL.git afl \
    && cd afl \
    && make


#
# Build SymCC simple backend
#
FROM builder_depend AS builder_symcc_simple
RUN mkdir symcc_build_simple \
    && cd symcc_build_simple \
    && cmake -G Ninja ~/symcc_source_main \
        -DLLVM_VERSION_FORCE=$BELCARRA_LLVM_VERSION \
        -DQSYM_BACKEND=OFF \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
    && ninja check


#
# Build LLVM libcxx using SymCC simple backend
#
FROM builder_symcc_simple AS builder_symcc_libcxx
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
# Build SymCC Qsym backend
#
FROM builder_symcc_libcxx AS builder_symcc_qsym
RUN mkdir symcc_build \
    && cd symcc_build \
    && cmake -G Ninja ~/symcc_source_main \
        -DLLVM_VERSION_FORCE=$BELCARRA_LLVM_VERSION \
        -DQSYM_BACKEND=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
    && ninja check


#
# Build Rust compiler with SymCC support
#
FROM builder_source AS builder_rust

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/symcc_build symcc_build

RUN export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd rust_source \
    && sed -e 's/#ninja = false/ninja = true/' \
        config.toml.example > config.toml \
    && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& is_x86_feature_detected!("sse2")/' \
        src/librustc_span/analyze_source_file.rs \
    && export SYMCC_RUNTIME_DIR=$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
    && /usr/bin/python3 ./x.py build


#
# Build additional tools
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
# Create final image
#
FROM builder_addons as builder_final

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        libllvm$BELCARRA_LLVM_VERSION \
        zlib1g \
    && sudo apt-get clean

RUN ln -s ~/symcc_source/util/pure_concolic_execution.sh symcc_build
COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/libcxx_symcc_install libcxx_symcc_install
COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/afl afl
RUN mkdir symcc_build_clang \
    && ln -s ~/symcc_build/symcc symcc_build_clang/clang \
    && ln -s ~/symcc_build/sym++ symcc_build_clang/clang++

ENV PATH $HOME/symcc_build_clang:$HOME/symcc_build:$PATH
ENV AFL_PATH $HOME/afl
ENV AFL_CC clang-$BELCARRA_LLVM_VERSION
ENV AFL_CXX clang++-$BELCARRA_LLVM_VERSION
ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install

RUN mkdir /tmp/output


#
# Build concolic C++ examples
#
FROM builder_final AS builder_examples_cpp

RUN cd belcarra_source/examples \
    && ./build_docker2.sh


#
# Build concolic Rust examples: Initialization
#
FROM builder_final AS builder_examples_rs_init

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bsdmainutils \
    && sudo apt-get clean


#
# Build concolic Rust examples: Rust source
#
FROM builder_examples_rs_init AS builder_examples_rs_src

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


#
# Build concolic Rust examples: Rust compiler
#
FROM builder_examples_rs_init AS builder_examples_rs_compiler

ARG RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
ARG BELCARRA_EXAMPLE=$HOME/belcarra_source/examples/source_0_original_1b_rs
ARG HEXDUMP="hexdump -v -C"

RUN cd $BELCARRA_EXAMPLE \
    && ./exec_rustc_file.sh -C passes=symcc -lSymRuntime
