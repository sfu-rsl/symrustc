.. SPDX-License-Identifier

.. Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

SymRustC: Presentation
**********************

SymRustC is a tool implemented in the Belcarra project
(\ `https://github.com/sfu-rsl <https://github.com/sfu-rsl>`_\ ) for practical and
efficient symbolic execution of Rust programs.

Demo video:
`https://www.youtube.com/watch?v=ySIWT2CDi40 <https://www.youtube.com/watch?v=ySIWT2CDi40>`_

SymRustC: Usage
***************

The execution of \ ``./build_all.sh``\ produces a sub-shell loaded
with an environment where the main driving script of SymRustC called
\ ``symrustc_hybrid.sh``\ can run. This script takes
an input corpus as parameter, and expects to be executed inside a Rust
project (i.e. inside a directory where one would usually invoke
\ ``cargo build``\ ).

Example:

.. code:: shell
  
  cd $(find . -name Cargo.toml -exec dirname {} \; | grep -v fuzz | sort -r | head -n 1) \
  && symrustc_hybrid.sh test

Note: Instead of building \ ``./build_all.sh``\ from scratch, end-users may
skip the build process, and download some pre-built docker image that
we also provide:
`https://github.com/sfu-rsl/symrustc_toolchain <https://github.com/sfu-rsl/symrustc_toolchain>`_ .
At the time of writing, this docker image is manually
uploaded. However it is supposed to reflect one of the latest state of
SymRustC, and thus should be close to \ ``./build_all.sh``\ .


License
*******

The contribution part of the project developed at Simon Fraser
University is licensed under the MIT license.

SPDX-License-Identifier: MIT
