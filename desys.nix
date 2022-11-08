# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: Unlicense
let
  l = builtins;
  /*
  A helper function which hides the complexities of dealing
  with 'system' properly from you, while still providing
  escape hatches when dealing with cross-compilation.
  */
  deSystemize = let
    iteration = cutoff: system: fragment:
      if ! (l.isAttrs fragment) || cutoff == 0
      then fragment
      else let
        recursed = l.mapAttrs (_: iteration (cutoff - 1) system) fragment;
      in
        if l.hasAttr "${system}" fragment
        then
          if l.isFunction fragment.${system}
          then recursed // {__functor = _: fragment.${system};}
          else recursed // fragment.${system}
        else recursed;
  in
    iteration 3;
in
  deSystemize
