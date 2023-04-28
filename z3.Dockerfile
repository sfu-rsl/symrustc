FROM ubuntu:22.10 AS base

SHELL ["/bin/bash", "-c"]

ARG LLVM_VERSION=15

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --reinstall ca-certificates \
        clang-$LLVM_VERSION \
        make \
        cmake \
        git \
        python3 \
    && apt-get clean

ENV PATH=/usr/lib/llvm-$LLVM_VERSION/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/lib/llvm-$LLVM_VERSION/lib:$LD_LIBRARY_PATH
ENV CC=clang
ENV CXX=clang++

WORKDIR /home



FROM base as builder

RUN git clone --depth 1 -b z3-4.11.2 https://github.com/Z3Prover/z3.git

ARG INSTALL_PREFIX=/home/dist

# https://github.com/season-lab/SymFusion/blob/main/docker/Dockerfile
RUN mkdir build \
    && cd build \
    && cmake ../z3 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    && make -j `nproc` \
    && make install



FROM ubuntu:22.10 AS dist

ARG INSTALL_PREFIX=/home/dist

COPY --from=builder $INSTALL_PREFIX $INSTALL_PREFIX
