#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

cd generated/llvm/sym++
grep sym_push_path_constraint sample.ll | cut -d ' ' -f 1-5,7,9-10 | sort | wc -l
grep sym_push_path_constraint sample.ll | cut -d ' ' -f 1-5,7,9-10 | sort -u | wc -l
