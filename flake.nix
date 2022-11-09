# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: Unlicense
{
  description = "Nix flakes with `systems` à la carte.";
  outputs = {self}: {
    __functor = self: self.lib.noSys;

    lib.noSys = inputs @ {systems ? import ./systems.nix, ...}: f: let
      systems' =
        if builtins.isPath systems || systems ? outPath
        then import systems
        else systems;
    in
      self.lib.eachSys systems' (sys: let
        f' = inputs: let
          # mapAttrs to deSys up to the same depths as in `self`
          inputs' = builtins.mapAttrs (_: self.lib.deSys sys) (builtins.removeAttrs inputs ["self"]);
          self' = self.lib.deSys sys (builtins.removeAttrs inputs.self ["inputs"]);
        in
          # must be recombined after `deSys` to avoid infinite recursion
          f (inputs' // {self = self';});
      in
        f' inputs);

    lib.deSys = import ./desys.nix;
    lib.eachSys = import ./eachSys.nix;

    templates.default = {
      path = ./tmpl;
      description = "Minimal flake with simplified systems handling.";
    };
  };
}
