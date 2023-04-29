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

FROM source as builder

ARG INSTALL_PREFIX=/home/dist

RUN jobs=$(python3 -c 'import os; print(len(os.sched_getaffinity(0)))') \
    && mkdir build \
    && cd build \
    && cmake $HOME/llvm-project/llvm \
    -G Ninja \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_ENABLE_PLUGINS=OFF \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_ENABLE_Z3_SOLVER=OFF \
    -DLLVM_PARALLEL_COMPILE_JOBS=$jobs \
    -DLLVM_TARGET_ARCH=x86_64 \
    -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-gnu \
    -DLLVM_INSTALL_UTILS=ON \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_ZLIB=ON \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_VERSION_SUFFIX=-rust-dev \
    -DCMAKE_INSTALL_MESSAGE=LAZY \
    -DCMAKE_C_COMPILER=cc \
    -DCMAKE_CXX_COMPILER=c++ \
    -DCMAKE_ASM_COMPILER=cc \
    -DCMAKE_C_FLAGS="-ffunction-sections -fdata-sections -fPIC -m64" \
    -DCMAKE_CXX_FLAGS="-ffunction-sections -fdata-sections -fPIC -m64" \
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-Bsymbolic -static-libstdc++" \
    -DCMAKE_MODULE_LINKER_FLAGS="-Wl,-Bsymbolic -static-libstdc++" \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,-Bsymbolic -static-libstdc++" \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_ASM_FLAGS="-ffunction-sections -fdata-sections -fPIC -m64" \
    -DCMAKE_BUILD_TYPE=Release \
    && cmake --build . --target install --config Release -- -j $jobs

FROM ubuntu:22.10 AS dist

ARG INSTALL_PREFIX=/home/dist

COPY --from=builder $INSTALL_PREFIX $INSTALL_PREFIX