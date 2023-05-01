# Let's use the same setup as the LLVM to have better caching.
FROM ubuntu:22.10 AS base

SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --reinstall ca-certificates \
    make \
    cmake \
    g++ \
    git \
    python3 \
    ninja-build \
    && apt-get clean

WORKDIR /home
ENV HOME=/home

FROM base as source

ARG BRANCH

RUN git clone --depth 1 -b $BRANCH https://github.com/sfu-rsl/llvm-project.git
RUN git -C llvm-project submodule update --init --recursive

RUN ln -s llvm-project/symcc symcc

RUN cd symcc \
    && current=$(git log -1 --pretty=format:%H) \
    # Note: Ideally, all submodules must also follow the change of version happening in the super-root project.
    && git checkout origin/main/$(git branch -r --contains "$current" | cut -d '/' -f 3-) \
    && cp -a . /home/symcc_main \
    && git checkout "$current" \
    && cd /home

#
# Build SymCC simple backend
#
FROM source AS builder

ARG LLVM_VERSION=15

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    clang-$LLVM_VERSION \
    llvm-$LLVM_VERSION-dev \
    llvm-$LLVM_VERSION-tools \
    python2 \
    python3-pip \
    zlib1g-dev \
    && apt-get clean
RUN pip3 install lit

ENV Z3_DIST_DIR=$HOME/z3_build/dist
ENV Z3_DIR=$Z3_DIST_DIR/lib/cmake/z3
COPY --from=ghcr.io/sfu-rsl/z3_dist:4.11.2 /home/dist $Z3_DIST_DIR

RUN mkdir build_simple \
    && cd build_simple \
    && cmake -G Ninja /home/symcc_main \
    -DLLVM_VERSION_FORCE=$LLVM_VERSION \
    -DQSYM_BACKEND=OFF \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DZ3_DIR=$Z3_DIR \
    && ninja check \
    && cd /home

RUN mkdir build_qsym \
    && cd build_qsym \
    && cmake -G Ninja /home/symcc_main \
    -DLLVM_VERSION_FORCE=$LLVM_VERSION \
    -DQSYM_BACKEND=ON \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DZ3_DIR=$Z3_DIR \
    && ninja check \
    && cd /home

#
# Build LLVM libcxx using SymCC simple backend
#
FROM builder AS builder_libcxx

RUN export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
    && mkdir -p build_libcxx \
    && cd build_libcxx \
    && cmake -G Ninja /home/llvm-project/llvm \
    -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_DISTRIBUTION_COMPONENTS="cxx;cxxabi;cxx-headers" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/home/libcxx_install \
    -DCMAKE_C_COMPILER=/home/build_simple/symcc \
    -DCMAKE_CXX_COMPILER=/home/build_simple/sym++ \
    && ninja distribution \
    && ninja install-distribution

FROM ubuntu:22.10 AS dist

WORKDIR /home

ARG SIMPLE_INSTALL_PREFIX=/home/dist_simple
ARG QSYM_INSTALL_PREFIX=/home/dist_qsym
ARG LIBCXX_INSTALL_PREFIX=/home/dist_libcxx

COPY --from=builder /home/build_simple $SIMPLE_INSTALL_PREFIX
COPY --from=builder /home/build_qsym $QSYM_INSTALL_PREFIX
COPY --from=builder /home/symcc_main/util/pure_concolic_execution.sh /
COPY --from=builder_libcxx /home/libcxx_install $LIBCXX_INSTALL_PREFIX
COPY --from=builder /home/z3_build/dist z3_build/dist
ENV LD_LIBRARY_PATH=/home/z3_build/dist/lib:$LD_LIBRARY_PATH