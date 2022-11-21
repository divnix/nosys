# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: Unlicense
let
  l = builtins // {
    # taken from `nixpkgs.lib.debug`
    traceIf =
      # Predicate to check
      pred:
      # Message that should be traced
      msg:
      # Value to return
      x: if pred then l.trace msg x else x;
  };


  cutat = 3;
  pad = n: l.concatStringsSep "" (l.genList (_: "\t") n);
  /*
  A helper function which hides the complexities of dealing
  with 'system' properly from you, while still providing
  escape hatches when dealing with cross-compilation.
  */
  deSystemize = debug: let
    iteration = name: cutoff: system: fragment:
      if ! (l.isAttrs fragment) || cutoff == 0
      then fragment
      else let
        recursed = l.mapAttrs (n:
          l.traceIf debug "deSys:${pad (cutat - cutoff)} visit ${n}"
          iteration n (cutoff - 1) system
        ) fragment;
      in
        if l.hasAttr "${system}" fragment
        then
          l.traceIf debug "deSys:${pad (cutat - cutoff)} hoist '${system}' onto '${name}' for direct access"
        (
          if l.isFunction fragment.${system}
          then recursed // {__functor = _: fragment.${system};}
          else recursed // fragment.${system}
        )
        else recursed;
  in
    iteration "." cutat;
in
  deSystemize
