#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

source git_current_branch.sh

img=end_user_main

SYMRUSTC_SOURCE=ghcr.io/sfu-rsl/symrustc_hybrid

sudo_docker_if_needed pull $SYMRUSTC_SOURCE
sudo_docker_if_needed build -f symrustc.Dockerfile --target builder_$img -t belcarra_$img --build-arg SYMRUSTC_SOURCE=$SYMRUSTC_SOURCE --build-arg SYMRUSTC_DIR_COPY=$SYMRUSTC_DIR_COPY .
sudo_docker_if_needed run -it --rm belcarra_$img
