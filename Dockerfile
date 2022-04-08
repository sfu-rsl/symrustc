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
# Prepare SymCC source
#
FROM builder_base AS builder_source

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-10 \
        g++ \
        git

COPY --chown=ubuntu:ubuntu . symcc_source

# Init submodules if they are not initialiazed yet
WORKDIR $HOME/symcc_source
RUN if git submodule status | grep "^-">/dev/null ; then \
    echo "Initializing submodules"; \
    git submodule init; \
    git submodule update; \
    fi
WORKDIR $HOME


#
# Prepare SymCC dependencies
#
FROM builder_source AS builder_depend

# Install dependencies
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cmake \
        libz3-dev \
        llvm-10-dev \
        llvm-10-tools \
        ninja-build \
        python2 \
        python3-pip \
        zlib1g-dev
RUN pip3 install lit
ENV PATH $HOME/.local/bin:$PATH

# Build AFL.
RUN git clone -b v2.56b https://github.com/google/AFL.git afl \
    && cd afl \
    && make

# Download the LLVM sources already so that we don't need to get them again when
# SymCC changes
RUN git clone -b llvmorg-10.0.1 --depth 1 https://github.com/llvm/llvm-project.git llvm_source


#
# Build SymCC with the simple backend
#
FROM builder_depend AS builder_simple
RUN mkdir symcc_build_simple \
    && cd symcc_build_simple \
    && cmake -G Ninja ~/symcc_source \
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
  && mkdir libcxx_symcc_build \
  && cd libcxx_symcc_build \
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
    && cmake -G Ninja ~/symcc_source \
        -DLLVM_VERSION_FORCE=10 \
        -DQSYM_BACKEND=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
    && ninja check


#
# Build SymCC additional tools
#
FROM builder_source AS builder_addons

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cargo

RUN cargo install --path symcc_source/util/symcc_fuzzing_helper


#
# The final image
#
FROM builder_source

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        libllvm10 \
        zlib1g

COPY --chown=ubuntu:ubuntu --from=builder_qsym $HOME/symcc_build symcc_build
COPY --chown=ubuntu:ubuntu --from=builder_addons $HOME/.cargo/bin/symcc_fuzzing_helper symcc_build/
RUN ln -s ~/symcc_source/util/pure_concolic_execution.sh symcc_build
COPY --chown=ubuntu:ubuntu --from=builder_qsym $HOME/libcxx_symcc_install libcxx_symcc_install
COPY --chown=ubuntu:ubuntu --from=builder_qsym $HOME/afl afl

ENV PATH $HOME/symcc_build:$PATH
ENV AFL_PATH $HOME/afl
ENV AFL_CC clang-10
ENV AFL_CXX clang++-10
ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install

RUN ln -s ~/symcc_source/sample.cpp
RUN mkdir /tmp/output
