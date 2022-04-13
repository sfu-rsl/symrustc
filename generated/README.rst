.. SPDX-License-Identifier

.. Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

SymRustC
********

SymRustC is a tool implemented in the Belcarra project
(\ `https://github.com/sfu-rsl <https://github.com/sfu-rsl>`_\ ) for practical and
efficient symbolic execution of Rust programs.

Like a compiler, the implementation of SymRustC is made of several
sub-components, that may come from different repositories. From a Rust
source in input, we basically obtain a concolic binary in output by
calling SymCC (its compiler part) at the LLVM level of the Rust
compilation process. In the end, the concolic binary enjoys the
property of being immediately compatible with the C++ runtime part of
SymCC (also designated as the QSYM or Z3 part), and can be used as
such, i.e. with the usual options and environment setting that we
usually put in place before running a SymCC concolic binary compiled
from C or C++.

The most notable components of SymRustC are listed below, they were in
particular combined and integrated together as Git submodules (from
top to bottom in nesting sub-encapsulation-module order):

- Rust compiler

  - \ `https://github.com/sfu-rsl/rust <https://github.com/sfu-rsl/rust>`_

    - \ `https://github.com/rust-lang/rust <https://github.com/rust-lang/rust>`_

- LLVM

  - \ `https://github.com/sfu-rsl/llvm-project <https://github.com/sfu-rsl/llvm-project>`_

    - \ `https://github.com/rust-lang/llvm-project <https://github.com/rust-lang/llvm-project>`_

      - \ `https://github.com/llvm/llvm-project <https://github.com/llvm/llvm-project>`_

- SymCC

  - \ `https://github.com/sfu-rsl/symcc <https://github.com/sfu-rsl/symcc>`_

    - \ `https://github.com/eurecom-s3/symcc <https://github.com/eurecom-s3/symcc>`_

- QSYM

  - \ `https://github.com/eurecom-s3/qsym <https://github.com/eurecom-s3/qsym>`_

    - \ `https://github.com/sslab-gatech/qsym <https://github.com/sslab-gatech/qsym>`_

- Z3

  - \ `https://github.com/Z3Prover/z3 <https://github.com/Z3Prover/z3>`_

Note that, at the time of writing, no modifications were made on the
last two components, QSYM and Z3.

Installation
************

SymRustC should be easily installable/usable on most platforms and
operating systems supported by the Rust compiler and SymCC.

A more detailed installation documentation is provided in this Dockerfile:

- SymRustC

  - \ `https://github.com/sfu-rsl/belcarra_symrustc/blob/1.46.0/Dockerfile <https://github.com/sfu-rsl/belcarra_symrustc/blob/1.46.0/Dockerfile>`_

Note that the use of Docker is not mandatory, e.g. the commands listed
in the Dockerfile may serve as examples of commands to run on any
system setting not too distant from the one present at the beginning
of the Dockerfile. (In the future, the SymRustC project may along its
run provide more examples of potentially other Dockerfiles and
configuration setting.)

In summary, this overall build file may also be relevant as invocation
starting-point:

- SymRustC

  - \ `https://github.com/sfu-rsl/belcarra_symrustc/blob/1.46.0/.github/workflows/build.yml <https://github.com/sfu-rsl/belcarra_symrustc/blob/1.46.0/.github/workflows/build.yml>`_
