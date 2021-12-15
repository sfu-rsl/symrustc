for i in 6 7 20 21 32 33 ; do mv -i "0_none/output_split$(printf '%02d' "$i")" 1_solvable ; done
for i in 14 15 40 ; do mv -i "0_none/output_split$(printf '%02d' "$i")" 2_unknown ; done
for i in 26 27 38 39 ; do mv -i "0_none/output_split$(printf '%02d' "$i")" 3_skipped ; done
