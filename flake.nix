# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: Unlicense
{
  description = "Nix flakes with `systems` à la carte.";
  outputs = {self}: let
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

    deSys = import ./desys.nix;
    eachSys = import ./eachSys.nix;
    noSys = debug: inputs @ {systems ? import ./systems.nix, ...}: f: let
      systems' =
        if l.isPath systems || systems ? outPath
        then import systems
        else systems;
    in
      l.traceIf debug "systems ${l.concatStringsSep ", " systems'}"
      eachSys systems' (sys: let
        f' = inputs: let
          # mapAttrs to deSys up to the same depths as in `self`
          inputs' = l.mapAttrs (_: deSys debug sys) (l.removeAttrs inputs ["self"]);
          self' = deSys debug sys (l.removeAttrs inputs.self ["inputs"]);
          # must be recombined after `deSys` to avoid infinite recursion
          args = inputs' // {self = self';};
        in
          f args;
      in
        f' inputs);

  in {

    debug = false;
    __functor = {debug, ... }: noSys debug;

    lib = {
      inherit eachSys;
      # no debug
      deSys = deSys false;
      noSys = noSys false;
    };

    templates.default = {
      path = ./tmpl;
      description = "Minimal flake with simplified systems handling.";
    };
  };
}
