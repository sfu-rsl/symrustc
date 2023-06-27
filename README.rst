.. SPDX-License-Identifier

.. Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

SymRustC
********

Installation
============

We first suppose that \ ``$PWD``\  is at the root directory of the
SymRustC project, and that Docker is installed. The execution
of \ ``./build_remote.sh``\  will install SymRustC inside a fresh
Docker container, copy some examples we provide in \ ``$PWD``\  to the
container, and open a sub-shell for the user to manually run SymRustC
on the desired examples. Note that \ ``./build_remote.sh``\  does not
modify anything in \ ``$PWD``\ . In the same spirit, the Docker
container is currently configured to be minimally invasive. It will be
removed once the sub-shell exits: any modifications made inside it
will irremediably be lost. One way to make modifications persistent
though is to mount a volume folder on the host into the guest
container:
`https://docs.docker.com/engine/reference/commandline/run <https://docs.docker.com/engine/reference/commandline/run/>`_.

Technically, \ ``./build_remote.sh``\  is downloading an uploaded image
that we have already built using a local \ ``./build_all.sh``\ . At
the time of writing, the upload is manually performed, so some best
efforts have been made for the image to represent one of the latest
states of the SymRustC project, if not the last. If some network
problems happen during the image retrieval, or to get the most
accurate version, one can always execute \ ``./build_all.sh``\  instead
of \ ``./build_remote.sh``\  to get the same result, and be able to run
SymRustC.

Usage (inside the sub-shell container)
======================================

SymRustC comes with two main scripts: a pure concolic engine
\ ``symrustc.sh``\ , and a hybrid engine
\ ``symrustc_hybrid.sh``\ . The use of the concolic
engine is not yet documented in this repository, as its design
architecture is being changed: it will be merged at some point with
the source of a sibling repository
`https://github.com/sfu-rsl/symrustc_toolchain <https://github.com/sfu-rsl/symrustc_toolchain>`_.
So for a pure concolic usage, we rather invite the user to refer to
the link.

The main hybrid engine \ ``symrustc_hybrid.sh``\  mandatorily takes one
input corpus as parameter, and this input must have at least one byte
(e.g. \ ``test``\ ). The script expects to be executed inside a Rust
project, i.e. inside a directory where one would usually invoke
\ ``cargo build``\ .

Example where \ ``examples/source_0_original_1c9_rs``\  is a directory
of a Rust project, with a \ ``Cargo.toml``\  at its root:

.. code:: shell
  
  cd examples/source_0_original_1c9_rs \
  && symrustc_hybrid.sh test

Note that the length of the input corpus may have an influence on the
hybrid fuzzing quality (e.g. speed of the tool to find a potential
bug), whereas its content may be arbitrary.

Overall, \ ``symrustc_hybrid.sh``\  takes the same options as
\ ``echo``\ . For example, without \ ``-n``\ , giving
\ ``test``\  alone will make the tool receive the 5 bytes input
\ ``test\n``\ , with a newline in the end.

Understanding the results
=========================

Since our SymRustC hybrid tool runs LibAFL in the end, we might get
the same hybrid-search experience than LibAFL in the end. In
particular, we will obtain as output log the same information produced
by LibAFL. As we configured LibAFL to execute 1 server and 2 clients,
the user will find the relevant output information be respectively
stored in \ ``_*_server``\ , \ ``_*_client1``\  and \ ``_*_client2``\ .

Example:

.. code:: shell
  
  ls _*_server _*_client1 _*_client2

For the most accurate and complete documentation, the user is then
referred to the source of LibAFL:
`https://github.com/AFLplusplus/LibAFL <https://github.com/AFLplusplus/LibAFL>`_,
as well as its generated documentation:
`https://aflplus.plus/libafl-book/ <https://aflplus.plus/libafl-book/>`_.
Note that while we are using a modified version of LibAFL in SymRustC,
we believe that all our modifications on LibAFL are only affecting its
execution engine, and not the way it is presenting its output.

As a summary of what we have understood from LibAFL's source and
documentation, output lines in \ ``_*_server``\  correspond to regular
printing of the state of the fuzzing experiment, i.e. printed at
regular intervals. The user can there notice that each line has a
field called \ ``objectives``\ , followed by a natural number. One of
the most important information here is to detect if this
\ ``objectives``\  field ever increases. If so, it means the tool has
found a problem, as we configured LibAFL to make the
\ ``objectives``\  be increased whenever our example binary exits with
an error status.

If the execution of a binary is not successful, it can be of crucial
importance to find out the input making the error happened, as well as
an informative error message following the termination of the
binary. Since all input and output interaction messages are stored in
\ ``_*_client1``\ or  \ ``_*_client2``\ , the user is then invited to
open these files.

Note that, whenever \ ``objectives``\  increases, most of the time the
client files will contain the input and output reports of the
problematic run. However, we also noticed rare situations where none
of the client files are showing the failing execution, despite a
detected positive \ ``objectives``\  number. At the time of writing,
more investigations on LibAFL's source and documentation might be
necessary to understand the reasons and conditions behind this.

Experimenting with a local Rust example
=======================================

Instead of using the SymRustC examples, one can import some custom
Rust examples from the host to the sub-shell, assuming the examples to
import are following some particular template and naming conventions,
which are further described below. This is necessary as the examples
to run with our tool will have to receive a generic pre-processing for
LibAFL, e.g. various instrumentation and dependency phases.

We provide a minimal template in 
`https://github.com/sfu-rsl/LibAFL/blob/rust_runtime_verbose/20221214/fuzzers/libfuzzer_rust_concolic/fuzzer/harness <https://github.com/sfu-rsl/LibAFL/blob/rust_runtime_verbose/20221214/fuzzers/libfuzzer_rust_concolic/fuzzer/harness>`_,
and invite the user to modify the body of \ ``main0``\  in the file
\ ``src/lib.rs``\  of the directory link. As \ ``main0``\  is called by
our LibAFL plug-in, we only suggest to modify the body of
\ ``main0``\  and not its type. It remains nevertheless possible to
insert additional dependencies to other Rust crates as desired. The
\ ``args``\  parameter of \ ``main0``\  corresponds to the list of
arguments provided from the command line. So, following standard shell
calling conventions, the fuzzing corpus will be provided by LibAFL at
position 1; position 0 is for the binary name.

Once the example is defined, importing it to the sub-shell can be made
by first putting it inside some folder internal to \ ``$PWD``\ . It
has to be inside \ ``$PWD``\ , because a default Docker configuration
would limit the access scope to arbitrary files in the
filesystem. Finally, on the host side, we set the path of that example
folder to the shell variable \ ``$SYMRUSTC_DIR_COPY``\  (the path can
be either absolute or relative to \ ``$PWD``\ ), and we export this
variable before calling \ ``./build_remote.sh``\ .

Note that it is not mandatory to give the precise root directory of a
Rust project in \ ``$SYMRUSTC_DIR_COPY``\ : any parent ancestor
directory inside \ ``$PWD``\  would work, because the whole content of
\ ``$SYMRUSTC_DIR_COPY``\  will be copied as such inside the
\ ``$HOME``\  folder of the guest container.

Example:

.. code:: shell
  
  SYMRUSTC_DIR_COPY=$PWD/examples ./build_remote.sh

Demo video
==========
`https://www.youtube.com/watch?v=ySIWT2CDi40 <https://www.youtube.com/watch?v=ySIWT2CDi40>`_

License
*******

The contribution part of the project developed at Simon Fraser
University is licensed under the MIT license.

SPDX-License-Identifier: MIT
