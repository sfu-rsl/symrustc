# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)


#
# Build end user environment main
#
ARG SYMRUSTC_SOURCE
FROM $SYMRUSTC_SOURCE:latest AS builder_end_user_main

COPY --chown=ubuntu:ubuntu examples examples
