#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

~/tmp/build/Isabelle2021-1/bin/isabelle jedit -d ~/tmp/afp-2021-1/thys Flatten_if.thy
