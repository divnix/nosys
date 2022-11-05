# Usage

```nix
# flake.nix
{
  inputs.nosys.url = "github:nrdxp/nosys";
  # file with list of systems: ["x86_64-linux" /* ... */ ]
  inputs.systems.url = "path:./flake/systems.nix";
  inputs.systems.flake = false;

  outputs = inputs @ {
    nosys,
    nixpkgs,
    ...
  }:
    nosys inputs ({self, nixpkgs, ...}: let
      inherit (nixpkgs.legacyPackages) pkgs;
    in {
      devShells.default = self.devShells.dev;
      devShells.dev = pkgs.mkShell {
        buildInputs = with pkgs; [/* ... */];
      };
    });
}
```

# Advanced

You may wish to use both system dependant and independant outputs in your flake:
```nix
# flake.nix
{
  inputs.nosys.url = "github:nrdxp/nosys";

  outputs = inputs @ {nosys, ...}: {
    # system dependant outputs
    inherit (nosys inputs (import ./flake/sys-out.nix)) devShells;

    # system independant outputs
    lib.inc = x: x + 1;
  }
}
```

# Systems

The system input can be a remote flake with a `systems` output or a path to a nix file defining the
plain list of systems.

`nosys` will use its own defaults if no flake input named `systems` exist. You can also
simply override systems as a list:
```nix
nosys (inputs' // {systems = ["x86_64-darwin"];}) # ({self, ...}:
```
