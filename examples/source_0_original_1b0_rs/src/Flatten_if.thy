(*
 * SPDX-License-Identifier
 * Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)
 *)

theory Flatten_if
  imports Isabelle_Meta_Model.Isabelle_Main1
begin

datatype 'a expr =
    If_t_e "'a expr" "'a expr" "'a expr"
  | And "'a expr" "'a expr"
  | Seq 'a "'a expr"
  | E 'a
  | SeqE 'a
  | Raw String.literal
  | Bool bool

definition "prog =
  If_t_e
    (And (E (STR ''buf_len >= root_len''))
         (And (E (STR ''buf[0 .. root_len] == *root''))
              (If_t_e (E (STR ''buf_len == root_len''))
                      (Bool True)
                      (If_t_e (E (STR ''buf_len == root_len + 1''))
                              (E (STR ''buf.ends_with(delim)''))
                              (Bool False)))))
    (Raw (STR ''cmd_root();''))
    (Raw (STR ''cmd_default(buf);''))"

fun lin where
   \<open>lin x =
(\<lambda> If_t_e (And b1 b2) case_t case_f \<Rightarrow>
   If_t_e b1
          (lin (If_t_e b2 case_t case_f))
          case_f
 | If_t_e (If_t_e cond (Bool True) case1_f) case_t case_f \<Rightarrow>
   If_t_e cond case_t (lin (If_t_e case1_f case_t case_f))
 | If_t_e (If_t_e cond case1_t (Bool False)) case_t case_f \<Rightarrow>
   If_t_e cond (lin (If_t_e case1_t case_t case_f)) case_f
 | x \<Rightarrow> x) x\<close>

fun expand where
   \<open>expand x =
(\<lambda> If_t_e (E cond) case_t case_f \<Rightarrow>
   Seq cond (If_t_e (SeqE cond) (expand case_t) (expand case_f))
 | x \<Rightarrow> x) x\<close>

definition \<open>prog' = expand (lin prog)\<close>

code_reflect' open META functions prog'

ML \<open>
local
  open META
in
  fun print pos n =
    let
      val writeln' = writeln o curry op ^ (replicate_string (4 * n) " ")
      fun print_debug msg pos = "println!(\"" ^ msg ^ " " ^ replicate_string 50 (Int.toString pos) ^ " {:?}\", buf);"
    in
      fn Seq (cond, If_t_e (SeqE _, case_t, case_f)) => 
          let
            val () =
              app
                writeln'
                [ "let r = " ^ cond ^ ";"
                , print_debug "ASSI" pos
                , "if r {" ]
            val pos = print (pos + 1) (n + 1) case_t
            val () = writeln' "} else {"
            val () = writeln' (print_debug "ELSE" pos)
            val pos = print (pos + 1) (n + 1) case_f
            val () = writeln' "}"
          in pos end
       | Raw s => let val () = writeln' s in pos end
       | _ => error "Not yet implemented"
  end
end
\<close>

ML \<open>
val _ = print 0 3 META.proga
\<close>

end
