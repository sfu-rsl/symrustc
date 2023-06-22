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

We first suppose that \ ``$PWD``\  is at the root directory of the
SymRustC project, and that Docker is installed. The execution
of \ ``./build_all.sh``\  will install SymRustC inside a fresh
Docker container, copy the full content of \ ``$PWD``\  inside the
container, and open a sub-shell for the user to manually run
SymRustC. Note that \ ``./build_all.sh``\  does not affect the content
of \ ``$PWD``\ . In the same spirit, the Docker container is by
default configured to be removed once the sub-shell exits: any
modifications made inside it will irremediably be lost.

To run SymRustC with some Rust examples, it is then suggested for the
user to put the examples of interests in \ ``$PWD``\  before invoking
\ ``./build_all.sh``\ . Note that the SymRustC project already
contains minimal examples, so one can alternatively execute
\ ``./build_all.sh``\  without anything at hand.

SymRustC comes with two main scripts: a pure concolic engine
\ ``symrustc.sh``\ , and a hybrid engine
\ ``symrustc_hybrid.sh``\ . The use of the concolic
engine is not yet documented in this repository, as its design
architecture may change soon, and be merged with the source of a
sibling repository
`https://github.com/sfu-rsl/symrustc_toolchain <https://github.com/sfu-rsl/symrustc_toolchain>`_.
So for a pure concolic usage, we rather invite the user to refer to
the later link.

The main hybrid engine \ ``symrustc_hybrid.sh``\ 
takes an input corpus as parameter, and expects to be executed inside
a Rust project (i.e. inside a directory where one would usually invoke
\ ``cargo build``\ ).

Example:

.. code:: shell
  
  cd $(find . -name Cargo.toml -exec dirname {} \; | grep -v fuzz | sort -r | head -n 1) \
  && symrustc_hybrid.sh test

Note that the length of the input corpus may have an influence on the
hybrid fuzzing quality (e.g. speed of the tool to find a potential
first bug), whereas its content may be arbitrary.

Overall, \ ``symrustc_hybrid.sh``\  takes the same
options as \ ``echo``\  (e.g. without \ ``-n``\ , giving
\ ``test``\  alone will make the tool receive a 5 bytes input,
containing a newline in the end).

License
*******

The contribution part of the project developed at Simon Fraser
University is licensed under the MIT license.

SPDX-License-Identifier: MIT
