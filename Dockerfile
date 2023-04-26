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

# error: failed to get `cc` as a dependency of package `bootstrap v0.0.0 (/home/ubuntu/belcarra_source0/src/rs/rust_source/src/bootstrap)`
# Caused by: failed to fetch `https://github.com/rust-lang/crates.io-index`
# Caused by: error reading from the zlib stream; class=Zlib (5)
# See: https://github.com/rust-lang/cargo/issues/10303#issuecomment-1015007926
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-$SYMRUSTC_LLVM_VERSION \
        cmake \
        g++ \
        git \
        ninja-build \
        python3-pip \
    && sudo apt-get clean

ENV SYMRUSTC_HOME=$HOME/belcarra_source
ENV SYMRUSTC_HOME_CPP=$SYMRUSTC_HOME/src/cpp
ENV SYMRUSTC_HOME_RS=$SYMRUSTC_HOME/src/rs
ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install
ENV SYMRUSTC_LIBAFL_SOLVING_DIR=$HOME/libafl/fuzzers/libfuzzer_rust_concolic
ENV SYMRUSTC_LIBAFL_TRACING_DIR=$HOME/libafl/libafl_concolic/test

# Setup Rust compiler source
ARG SYMRUSTC_RUST_VERSION
ARG SYMRUSTC_BRANCH
RUN if [[ -v SYMRUSTC_RUST_VERSION ]] ; then \
      git clone --depth 1 -b $SYMRUSTC_RUST_VERSION https://github.com/sfu-rsl/rust.git rust_source; \
    else \
      git clone --depth 1 -b "$SYMRUSTC_BRANCH" https://github.com/sfu-rsl/symrustc.git belcarra_source0; \
      ln -s ~/belcarra_source0/src/rs/rust_source; \
    fi

# Init submodules
RUN [[ -v SYMRUSTC_RUST_VERSION ]] && dir='rust_source' || dir='belcarra_source0' ; \
    git -C "$dir" submodule update --init --recursive

#
RUN ln -s ~/rust_source/src/llvm-project llvm_source
RUN git clone -b rust_runtime/20220326 https://github.com/sfu-rsl/LibAFL.git libafl
RUN ln -s ~/llvm_source/symcc symcc_source

# Note: Depending on the commit revision, the Rust compiler source may not have yet a SymCC directory. In this docker stage, we treat such case as a "non-aborting failure" (subsequent stages may raise different errors).
RUN if [ -d symcc_source ] ; then \
      cd symcc_source \
      && current=$(git log -1 --pretty=format:%H) \
# Note: Ideally, all submodules must also follow the change of version happening in the super-root project.
      && git checkout origin/main/$(git branch -r --contains "$current" | cut -d '/' -f 3-) \
      && cp -a . ~/symcc_source_main \
      && git checkout "$current"; \
    fi

# Download AFL
RUN git clone --depth 1 -b v2.56b https://github.com/google/AFL.git afl

# Download Z3
RUN git clone --depth 1 -b z3-4.11.2 https://github.com/Z3Prover/z3.git


#
# Set up project dependencies
#
FROM builder_source AS builder_depend

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        llvm-$SYMRUSTC_LLVM_VERSION-dev \
        llvm-$SYMRUSTC_LLVM_VERSION-tools \
        python2 \
        zlib1g-dev \
    && sudo apt-get clean
RUN pip3 install lit
ENV PATH=$HOME/.local/bin:$PATH

# https://github.com/season-lab/SymFusion/blob/main/docker/Dockerfile
RUN mkdir z3_build \
    && cd z3_build \
    && cmake ~/z3 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=`pwd`/dist \
    && make -j `nproc` \
    && make install


#
# Build AFL
#
FROM builder_source AS builder_afl

RUN cd afl \
    && make


#
# Build SymCC simple backend
#
FROM builder_depend AS builder_symcc_simple
RUN mkdir symcc_build_simple \
    && cd symcc_build_simple \
    && cmake -G Ninja ~/symcc_source_main \
        -DLLVM_VERSION_FORCE=$SYMRUSTC_LLVM_VERSION \
        -DQSYM_BACKEND=OFF \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_DIR=~/z3_build/dist/lib/cmake/z3 \
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
  -DCMAKE_INSTALL_PREFIX=$SYMCC_LIBCXX_PATH \
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
        -DLLVM_VERSION_FORCE=$SYMRUSTC_LLVM_VERSION \
        -DQSYM_BACKEND=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_DIR=~/z3_build/dist/lib/cmake/z3 \
    && ninja check


#
# Build SymLLVM
#
FROM builder_source AS builder_symllvm

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
COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/z3_build z3_build

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
ENV SYMRUSTC_LIBAFL_EXAMPLE0=$HOME/belcarra_source/examples/source_0_original_1c0_rs
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
ARG SYMRUSTC_EXEC_CONCOLIC_OFF=yes

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_RS/fold_symrustc_build.sh

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_RS/fold_symrustc_run.sh


#
# Set up Ubuntu/Rust environment
#
FROM builder_symrustc AS builder_base_rust

ENV RUSTUP_HOME=$HOME/rustup \
    CARGO_HOME=$HOME/cargo \
    PATH=$HOME/cargo/bin:$PATH \
    RUST_VERSION=1.63.0

# https://github.com/rust-lang/docker-rust/blob/2301a502c3ff8bbf30c32a6ef2114f3b363c4553/1.63.0/bullseye/Dockerfile
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='5cc9ffd1026e82e7fb2eec2121ad71f4b0f044e88bca39207b3f6b769aaa799c' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='48c5ecfd1409da93164af20cf4ac2c6f00688b15eb6ba65047f654060c844d85' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='e189948e396d47254103a49c987e7fb0e5dd8e34b200aa4481ecc4b8e41fb929' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='0e0be29c560ad958ba52fcf06b3ea04435cb3cd674fbe11ce7d954093b9504fd' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.25.1/${rustArch}/rustup-init"; \
    curl -O "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}

RUN rustup component add rustfmt


#
# Build LibAFL tracing runtime
#
FROM builder_base_rust AS builder_libafl_tracing

ARG SYMRUSTC_CI

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      mkdir ~/libafl/target; \
    else \
      cd $SYMRUSTC_LIBAFL_TRACING_DIR \
      && cargo build -p runtime_test \
      && cargo build -p dump_constraints; \
    fi


#
# Build LibAFL tracing runtime main
#
FROM builder_symrustc_main AS builder_libafl_tracing_main

COPY --chown=ubuntu:ubuntu --from=builder_libafl_tracing $HOME/libafl/target $HOME/libafl/target

# Pointing to the Rust runtime back-end
RUN cd -P $SYMRUSTC_RUNTIME_DIR/.. \
    && ln -s ~/libafl/target/debug "$(basename $SYMRUSTC_RUNTIME_DIR)0"

RUN source $SYMRUSTC_HOME_RS/libafl_swap.sh \
    && swap


#
# Build concolic Rust examples for LibAFL tracing
#
FROM builder_libafl_tracing_main AS builder_libafl_tracing_example

ARG SYMRUSTC_CI
ARG SYMRUSTC_LIBAFL_EXAMPLE=$HOME/belcarra_source/examples/source_0_original_1c_rs
ARG SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_TRACING

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EXAMPLE \
      && $SYMRUSTC_HOME_RS/libafl_tracing_build.sh; \
    fi

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EXAMPLE \
# Note: target_cargo_off can be kept but its printed trace would be less informative than the one of target_cargo_on, and by default, only the first trace seems to be printed.
      && rm -rf target_cargo_off \
      && $SYMRUSTC_HOME_RS/libafl_tracing_run.sh test; \
    fi


#
# Build LibAFL solving runtime
#
FROM builder_base_rust AS builder_libafl_solving

ARG SYMRUSTC_CI

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cargo install cargo-make; \
    fi

COPY --chown=ubuntu:ubuntu src/rs belcarra_source/src/rs
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
ARG SYMRUSTC_LIBAFL_EXAMPLE=$SYMRUSTC_LIBAFL_EXAMPLE0

# Updating the harness
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer \
      && rm -rf harness \
      && cp -R $SYMRUSTC_LIBAFL_EXAMPLE harness; \
    fi

# Building the client-server main fuzzing loop
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      mkdir $SYMRUSTC_LIBAFL_SOLVING_DIR/target; \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_SOLVING_DIR \
      && PATH=~/clang_symcc_off:"$PATH" cargo make test; \
    fi

# Building the client-server main fuzzing loop with the harness as sanitized
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      mkdir $SYMRUSTC_LIBAFL_SOLVING_DIR/target; \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer \
      && $SYMRUSTC_HOME_RS/libafl_cargo.sh; \
    fi


#
# Build LibAFL solving runtime main
#
FROM builder_symrustc_main AS builder_libafl_solving_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
# Installing "nc" to later check if a given port is opened or closed
        netcat-openbsd \
        psmisc \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu --from=builder_libafl_solving $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer/target $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer/target
COPY --chown=ubuntu:ubuntu --from=builder_libafl_solving $SYMRUSTC_LIBAFL_SOLVING_DIR/runtime/target $SYMRUSTC_LIBAFL_SOLVING_DIR/runtime/target

# Pointing to the Rust runtime back-end
RUN cd -P $SYMRUSTC_RUNTIME_DIR/.. \
    && ln -s $SYMRUSTC_LIBAFL_SOLVING_DIR/runtime/target/release "$(basename $SYMRUSTC_RUNTIME_DIR)0"


#
# Build concolic Rust examples for LibAFL solving
#
FROM builder_libafl_solving_main AS builder_libafl_solving_example

ARG SYMRUSTC_CI
ARG SYMRUSTC_LIBAFL_EXAMPLE=$SYMRUSTC_LIBAFL_EXAMPLE0
ARG SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_SOLVING
ARG SYMRUSTC_LIBAFL_SOLVING_OBJECTIVE=yes

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EXAMPLE \
      && $SYMRUSTC_HOME_RS/libafl_solving_build.sh; \
    fi

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EXAMPLE \
      && $SYMRUSTC_HOME_RS/libafl_solving_run.sh test; \
    fi


#
# Build additional tools
#
FROM builder_symrustc AS builder_addons

ARG SYMRUSTC_CI
ARG SYMRUSTC_SKIP_FAIL

COPY --chown=ubuntu:ubuntu src/rs/env0.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/env.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/parse_args0.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/parse_args.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/symcc_fuzzing_helper.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/wait_all.sh $SYMRUSTC_HOME_RS/

RUN $SYMRUSTC_HOME_RS/symcc_fuzzing_helper.sh


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
