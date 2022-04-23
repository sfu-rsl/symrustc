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
    && sed -e 's/#ninja = false/ninja = true/' \
        config.toml.example > config.toml \
    && /usr/bin/python3 ./x.py build
