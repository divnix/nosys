# shamelessly stolen from, to modify non-sys handling:
# https://github.com/numtide/flake-utils/blob/master/default.nix
#
#
# Builds a map from <attr>=value to <attr>.<system>=value for each system,
# except for the `hydraJobs` attribute, where it maps the inner attributes,
# from hydraJobs.<attr>=value to hydraJobs.<attr>.<system>=value.
#
let
  # nixpkgs.lib.systems.doubles.all
  allKnownSystems = [
    "i686-cygwin"
    "x86_64-cygwin"
    "x86_64-darwin"
    "i686-darwin"
    "aarch64-darwin"
    "armv7a-darwin"
    "i686-freebsd"
    "x86_64-freebsd"
    "aarch64-genode"
    "i686-genode"
    "x86_64-genode"
    "x86_64-solaris"
    "js-ghcjs"
    "aarch64-linux"
    "armv5tel-linux"
    "armv6l-linux"
    "armv7a-linux"
    "armv7l-linux"
    "i686-linux"
    "m68k-linux"
    "microblaze-linux"
    "microblazeel-linux"
    "mipsel-linux"
    "mips64el-linux"
    "powerpc64-linux"
    "powerpc64le-linux"
    "riscv32-linux"
    "riscv64-linux"
    "s390-linux"
    "s390x-linux"
    "x86_64-linux"
    "mmix-mmixware"
    "aarch64-netbsd"
    "armv6l-netbsd"
    "armv7a-netbsd"
    "armv7l-netbsd"
    "i686-netbsd"
    "m68k-netbsd"
    "mipsel-netbsd"
    "powerpc-netbsd"
    "riscv32-netbsd"
    "riscv64-netbsd"
    "x86_64-netbsd"
    "aarch64_be-none"
    "aarch64-none"
    "arm-none"
    "armv6l-none"
    "avr-none"
    "i686-none"
    "microblaze-none"
    "microblazeel-none"
    "msp430-none"
    "or1k-none"
    "m68k-none"
    "powerpc-none"
    "powerpcle-none"
    "riscv32-none"
    "riscv64-none"
    "rx-none"
    "s390-none"
    "s390x-none"
    "vc4-none"
    "x86_64-none"
    "i686-openbsd"
    "x86_64-openbsd"
    "x86_64-redox"
    "wasm64-wasi"
    "wasm32-wasi"
    "x86_64-windows"
    "i686-windows"
  ];
in
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
          else {${system} = builtins.removeAttrs ret.${key} allKnownSystems;};
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
