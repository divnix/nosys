# SPDX-FileCopyrightText: 2020 zimbatm
# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: MIT

# shamelessly stolen from, to modify non-sys handling:
# https://github.com/numtide/flake-utils/blob/master/default.nix
#
#
# Builds a map from <attr>=value to <attr>.<system>=value for each system,
# except for the `hydraJobs` attribute, where it maps the inner attributes,
# from hydraJobs.<attr>=value to hydraJobs.<attr>.<system>=value.
#
systems: f: let
  # Taken from <nixpkgs/lib/attrsets.nix>
  isDerivation = x: builtins.isAttrs x && x ? type && x.type == "derivation";

  # Used to match Hydra's convention of how to define jobs. Basically transforms
  #
  #     hydraJobs = {
  #       hello = <derivation>;
  #       haskellPackages.aeson = <derivation>;
  #     }
  #
  # to
  #
  #     hydraJobs = {
  #       hello.x86_64-linux = <derivation>;
  #       haskellPackages.aeson.x86_64-linux = <derivation>;
  #     }
  #
  # if the given flake does `eachSystem [ "x86_64-linux" ] { ... }`.
  pushDownSystem = system: merged:
    builtins.mapAttrs
    (name: value:
      if ! (builtins.isAttrs value)
      then value
      else if isDerivation value
      then (merged.${name} or {}) // {${system} = value;}
      else pushDownSystem system (merged.${name} or {}) value);

  # Merge together the outputs for all systems.
  op = attrs: system: let
    ret = f system;
    op = attrs: key: let
      appendSystem = key: system: ret:
        if builtins.substring 0 1 key == "_"
        then ret.${key}
        else if key == "hydraJobs"
        then (pushDownSystem system (attrs.hydraJobs or {}) ret.hydraJobs)
        else {${system} = ret.${key};};
    in
      attrs
      // {
        ${
          if builtins.substring 0 2 key == "__"
          then key
          else if builtins.substring 0 1 key == "_"
          then builtins.substring 1 (-1) key
          else key
        } =
          (attrs.${key} or {})
          // (appendSystem key system ret);
      };
  in
    builtins.foldl' op attrs (builtins.attrNames ret);
in
  builtins.foldl' op {} systems
