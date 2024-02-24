# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: Unlicense
{
  description = "Nix flakes with `systems` à la carte.";
  outputs = {self}: {
    __functor = self: self.lib.noSys;

    lib.noSys = inputs @ {
      systems ? import ./systems.nix,
      config ? {},
      ...
    }: f: let
      systems' =
        if builtins.isPath systems || systems ? outPath
        then import systems
        else systems;
    in
      self.lib.eachSys systems' (system: let
        f' = inputs: let
          # mapAttrs to deSys up to the same depths as in `self`
          inputs' = builtins.mapAttrs (k: v: let
            input = self.lib.deSys system v;
          in
            if
              k
              == "pkgs"
              && v ? legacyPackages
              && v.inputs == {}
              && builtins.pathExists "${v}/default.nix"
            then let
              pkgs =
                if inputs ? config && inputs.config != {}
                then
                  import v {
                    inherit system config;
                  }
                else input.legacyPackages;
            in
              pkgs // input
            else input) (builtins.removeAttrs inputs ["self"]);
          self' = self.lib.deSys system (builtins.removeAttrs inputs.self ["inputs"]);
        in
          # must be recombined after `deSys` to avoid infinite recursion
          f ((
              if inputs ? pkgs && inputs.pkgs ? lib
              then {inherit (inputs.pkgs) lib;}
              else {}
            )
            // inputs'
            // {self = self';});
      in
        f' inputs);

    lib.deSys = import ./desys.nix;
    lib.eachSys = import ./eachSys.nix;

    templates = {
      default = {
        path = ./tmpls/default;
        description = "Minimal flake with simplified systems handling.";
      };
      local = {
        path = ./tmpls/local;
        description = "Minimal local development environment flake.";
      };
    };
  };
}
