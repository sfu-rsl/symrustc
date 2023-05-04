#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

#

dir=libafl_stats
fic_thy0=sha
fic_thy=${fic_thy0}.thy

$SYMRUSTC_HOME_RS/libafl_solving_run0.sh "$@"

mkdir $dir
pushd $dir >/dev/null

grep 'Hello\|command\|BBBB\|0000000000000000 A\|0000000000000000 1' ~/libafl_client1 > libafl_trace

csplit -n 6 -f libafl_trace_split libafl_trace '/0000000000000000 A/' '{*}'

echo "theory $fic_thy0" > $fic_thy

cat >> $fic_thy <<"EOF"
  imports Main
begin

declare [[ML_print_depth = 30]]

ML \<open>
val l =
EOF

sha1sum -b libafl_trace_split* | sed -r 's/(.*) (.*)/  ("\1", "\2") :: /' | tee -a $fic_thy

cat >> $fic_thy <<"EOF"
  []
  |> Symtab.make_list
  |> Symtab.dest
  |> sort_by (fn (_, l) => hd l)

val out1 = l
  |> map (fn (hash, l) => (hash, length l, map (fn s => String.extract (s, 19, NONE)) l))

val out2 = l
  |> tap (fn _ => app writeln [ "#!/bin/bash",
                                "set -euxo pipefail",
                                "",
                                "v=( \\"])
  |> map (fn (_, l) => writeln ("  '" ^ String.extract (hd l, 1, NONE) ^ "' \\"))
  |> tap (fn _ => app writeln [ ")",
                                "",
                                "for i in ${v[@]}",
                                "do",
                                "    ln -s \"../$i\"",
                                "done" ])
\<close>
end
EOF

popd >/dev/null
