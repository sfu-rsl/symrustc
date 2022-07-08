#

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -x
tar cf rust_source.tar rust_source
mv -i rust_source ..

sudo -v && ((date -R ; /usr/bin/time -v sudo docker build . -f full_runtime.Dockerfile ; date -R) 2>&1 | tee ../log_$(date '+%F_%T' | tr -d ':-'))

rm rust_source.tar
mv -i ../rust_source .
set +x
