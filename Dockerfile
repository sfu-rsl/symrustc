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
FROM ubuntu:22.10 AS builder_base

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

ENV SYMRUSTC_LLVM_VERSION=15

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-tools-$SYMRUSTC_LLVM_VERSION \
        mlir-$SYMRUSTC_LLVM_VERSION-tools \
        libmlir-$SYMRUSTC_LLVM_VERSION-dev \
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
ENV SYMRUSTC_LIBAFL_SOLVING_INST_DIR=$HOME/libafl/fuzzers/libfuzzer_rust_concolic_instance
ENV SYMRUSTC_LIBAFL_EX_IMAGE_DIR=$HOME/libafl/fuzzers/libfuzzer_stb_image_concolic
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
RUN git clone -b rust_runtime_verbose/20221214 https://github.com/sfu-rsl/LibAFL.git libafl
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
    && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
        compiler/rustc_span/src/analyze_source_file.rs \
    && export SYMCC_RUNTIME_DIR=$SYMRUSTC_RUNTIME_DIR \
    && /usr/bin/python3 ./x.py build --stage 2

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
    RUST_VERSION=1.65.0

# https://github.com/rust-lang/docker-rust/blob/76e3311a6326bc93a1e96ad7ae06c05763b62b18/1.65.0/bullseye/Dockerfile
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

# Building the client-server main fuzzing loop
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      mkdir $SYMRUSTC_LIBAFL_SOLVING_DIR/target; \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_SOLVING_DIR \
      && PATH=~/clang_symcc_off:"$PATH" cargo make test; \
    fi


#
# Build LibAFL solving instance runtime
#
FROM builder_base_rust AS builder_libafl_solving_inst

ARG SYMRUSTC_CI

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cargo install cargo-make; \
    fi

RUN rm -rf $SYMRUSTC_LIBAFL_SOLVING_INST_DIR
COPY --chown=ubuntu:ubuntu libfuzzer_rust_concolic_instance $SYMRUSTC_LIBAFL_SOLVING_INST_DIR

# Building the client-server main fuzzing loop
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      mkdir $SYMRUSTC_LIBAFL_SOLVING_INST_DIR/target; \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_SOLVING_INST_DIR \
      && PATH=~/clang_symcc_off:"$PATH" cargo make test; \
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

COPY --chown=ubuntu:ubuntu --from=builder_libafl_solving $SYMRUSTC_LIBAFL_SOLVING_DIR/target $SYMRUSTC_LIBAFL_SOLVING_DIR/target

# Pointing to the Rust runtime back-end
RUN cd -P $SYMRUSTC_RUNTIME_DIR/.. \
    && ln -s $SYMRUSTC_LIBAFL_SOLVING_DIR/target/release "$(basename $SYMRUSTC_RUNTIME_DIR)0"

# TODO: file name to be generalized
RUN ln -s $SYMRUSTC_HOME_RS/libafl_solving_bin.sh $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer/target_symcc0.out


#
# Build LibAFL solving instance runtime main
#
FROM builder_symrustc_main AS builder_libafl_solving_inst_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
# Installing "nc" to later check if a given port is opened or closed
        netcat-openbsd \
        psmisc \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu --from=builder_libafl_solving_inst $SYMRUSTC_LIBAFL_SOLVING_INST_DIR/target $SYMRUSTC_LIBAFL_SOLVING_INST_DIR/target

# Pointing to the Rust runtime back-end
RUN cd -P $SYMRUSTC_RUNTIME_DIR/.. \
    && ln -s $SYMRUSTC_LIBAFL_SOLVING_INST_DIR/target/release "$(basename $SYMRUSTC_RUNTIME_DIR)0"

# TODO: file name to be generalized
RUN ln -s $SYMRUSTC_HOME_RS/libafl_solving_bin.sh $SYMRUSTC_LIBAFL_SOLVING_INST_DIR/fuzzer/target_symcc0.out


#
# Build concolic Rust examples for LibAFL solving
#
FROM builder_libafl_solving_main AS builder_libafl_solving_example

ARG SYMRUSTC_CI
ARG SYMRUSTC_LIBAFL_EXAMPLE=$HOME/belcarra_source/examples/source_0_original_1c_rs
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
# Build concolic Rust examples for LibAFL solving instance
#
FROM builder_libafl_solving_inst_main AS builder_libafl_solving_inst_example

ARG SYMRUSTC_CI
ARG SYMRUSTC_LIBAFL_EXAMPLE=$HOME/belcarra_source/examples/source_0_original_1c0_rs
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
      && $SYMRUSTC_HOME_RS/libafl_solving_inst_run.sh test; \
    fi


#
# Build LibAFL ex image runtime
#
FROM builder_base_rust AS builder_libafl_ex_image

ARG SYMRUSTC_CI

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cargo install cargo-make; \
    fi

# Building the client-server main fuzzing loop
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      mkdir $SYMRUSTC_LIBAFL_EX_IMAGE_DIR/fuzzer/target $SYMRUSTC_LIBAFL_EX_IMAGE_DIR/runtime/target; \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EX_IMAGE_DIR \
      && PATH=~/clang_symcc_off:"$PATH" cargo make test; \
    fi


#
# Build LibAFL ex image runtime main
#
FROM builder_symrustc_main AS builder_libafl_ex_image_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
# Installing "nc" to later check if a given port is opened or closed
        netcat-openbsd \
        psmisc \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu --from=builder_libafl_ex_image $SYMRUSTC_LIBAFL_EX_IMAGE_DIR/target $SYMRUSTC_LIBAFL_EX_IMAGE_DIR/target
COPY --chown=ubuntu:ubuntu --from=builder_libafl_ex_image $SYMRUSTC_LIBAFL_EX_IMAGE_DIR/fuzzer/target_symcc.out $SYMRUSTC_LIBAFL_EX_IMAGE_DIR/fuzzer/target_symcc.out


#
# Build concolic Rust examples for LibAFL ex image
#
FROM builder_libafl_ex_image_main AS builder_libafl_ex_image_example

ARG SYMRUSTC_CI
ARG SYMRUSTC_LIBAFL_EXAMPLE=$SYMRUSTC_LIBAFL_EX_IMAGE_DIR
ARG SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_SOLVING
ARG SYMRUSTC_LIBAFL_EX_IMAGE_OBJECTIVE=yes

RUN if true ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EXAMPLE \
      && $SYMRUSTC_HOME_RS/libafl_ex_image_run.sh test; \
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
# Build concolic Rust examples - set up project source - coreutils
#
FROM builder_symrustc_main AS builder_examples_rs_source_coreutils

RUN git clone --depth 1 https://github.com/uutils/coreutils.git


#
# Build concolic Rust examples - set up project source - coreutils - libafl
#
FROM builder_libafl_solving_main AS builder_examples_rs_source_coreutils_libafl

COPY --chown=ubuntu:ubuntu --from=builder_examples_rs_source_coreutils $HOME/coreutils coreutils


#
# Build concolic Rust examples - coreutils
#
FROM builder_examples_rs_source_coreutils AS builder_examples_rs_coreutils

RUN cd coreutils \
    && $SYMRUSTC_HOME_RS/env.sh $SYMRUSTC_CARGO install coreutils || echo "error exit code: $?"

# OK
RUN cd coreutils/src/uu/base32 \
    && $SYMRUSTC_HOME_RS/symrustc_build.sh \
    && $SYMRUSTC_HOME_RS/symrustc_run.sh test

# PB: libc "splice" not yet implemented
RUN cd coreutils/src/uu/cat \
    && $SYMRUSTC_HOME_RS/symrustc_build.sh \
    && $SYMRUSTC_HOME_RS/symrustc_run.sh test

# OK
RUN cd coreutils/src/uu/cut \
    && $SYMRUSTC_HOME_RS/symrustc_build.sh \
    && SYMRUSTC_BIN_ARGS='-d a -f 3-' $SYMRUSTC_HOME_RS/symrustc_run.sh a0a1a2

# PB: program not implemented to read its concolic argument from stdin nor file
RUN cd coreutils/src/uu/echo \
    && $SYMRUSTC_HOME_RS/symrustc_build.sh \
    && SYMRUSTC_BIN_ARGS='$(cat /dev/stdin)' $SYMRUSTC_HOME_RS/symrustc_run.sh test

# OK
RUN cd coreutils/src/uu/expand \
    && $SYMRUSTC_HOME_RS/symrustc_build.sh \
    && SYMRUSTC_BIN_ARGS='-t 3' $SYMRUSTC_HOME_RS/symrustc_run.sh -e 'a\t\t\tb'

# OK
RUN cd coreutils/src/uu/sort \
    && $SYMRUSTC_HOME_RS/symrustc_build.sh \
    && $SYMRUSTC_HOME_RS/symrustc_run.sh -ne 'b\nd\nc\na'


#
# Build concolic Rust examples - coreutils - libafl
#
FROM builder_examples_rs_source_coreutils_libafl AS builder_examples_rs_coreutils_libafl

ARG SYMRUSTC_CI
ARG SYMRUSTC_LIBAFL_EXAMPLE=$HOME/coreutils/src/uu/sort
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
      && $SYMRUSTC_HOME_RS/libafl_solving_run.sh -ne 'b\nd\nc\na'; \
    fi


#
# Build concolic Rust examples - set up project source - linux
#
FROM builder_symrustc AS builder_examples_rs_source_linux

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
# https://github.com/ClangBuiltLinux/dockerimage.git
# SPDX-License-Identifier: Apache-2.0
        bc \
        binutils \
        binutils-aarch64-linux-gnu \
        binutils-arm-linux-gnueabi \
        binutils-mips-linux-gnu \
        binutils-mipsel-linux-gnu \
        binutils-powerpc-linux-gnu \
        binutils-powerpc64-linux-gnu \
        binutils-powerpc64le-linux-gnu \
        binutils-riscv64-linux-gnu \
        binutils-s390x-linux-gnu \
        bison \
        ca-certificates \
        ccache \
        clang-$SYMRUSTC_LLVM_VERSION \
        cpio \
        curl \
        expect \
        flex \
        git \
        gnupg \
        libelf-dev \
        libssl-dev \
        lld-$SYMRUSTC_LLVM_VERSION \
        llvm-$SYMRUSTC_LLVM_VERSION \
        lz4 \
        make \
        opensbi \
        openssl \
        ovmf \
        qemu-efi-aarch64 \
        qemu-system-arm \
        qemu-system-mips \
        qemu-system-misc \
        qemu-system-ppc \
        qemu-system-x86 \
        u-boot-tools \
        xz-utils \
        zstd \
    && sudo apt-get clean

RUN git clone --depth 1 https://github.com/Rust-for-Linux/linux.git
RUN git clone --depth 1 https://github.com/Rust-for-Linux/rust-out-of-tree-module.git

COPY --chown=ubuntu:ubuntu src/rs/env0.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/env.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/parse_args0.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/parse_args.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/wait_all.sh $SYMRUSTC_HOME_RS/


#
# Build concolic Rust examples - linux
#
FROM builder_examples_rs_source_linux AS builder_examples_rs_linux

COPY --chown=ubuntu:ubuntu generated/linux/.config linux/

RUN cd linux \
    && $SYMRUSTC_HOME_RS/env.sh $SYMRUSTC_CARGO install --locked --version $(scripts/min-tool-version.sh bindgen) bindgen

# FIXME: this option is on to avoid the link of vmlinux to fail (see linux/scripts/link-vmlinux.sh)
ARG SYMRUSTC_SKIP_CONCOLIC_ON=yes

ARG SYMRUSTC_MAKE='make CARGO="'$SYMRUSTC_CARGO'" HOSTRUSTC="$RUSTC" RUSTC="$RUSTC" SYMRUSTC_RUSTFLAGS="$RUSTFLAGS" LLVM_SUFFIX="-'$SYMRUSTC_LLVM_VERSION'" LLVM=1'

RUN cd linux \
    && sed -i -e 's/export rust_common_flags/SYMRUSTC_RUSTFLAGS =\n&/' \
              -e 's/-Wclippy::dbg_macro/& $(SYMRUSTC_RUSTFLAGS)/' \
        Makefile \
    && $SYMRUSTC_HOME_RS/env.sh "$SYMRUSTC_MAKE"

RUN cd rust-out-of-tree-module \
    && $SYMRUSTC_HOME_RS/env.sh "$SYMRUSTC_MAKE KDIR=$HOME/linux"


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
