<!--
SPDX-FileCopyrightText: 2022 The Standard Authors

SPDX-License-Identifier: Unlicense
-->
# Usage

```nix
# flake.nix
{
  inputs.nosys.url = "github:divnix/nosys";
  # file with list of systems: ["x86_64-linux" /* ... */ ]
  inputs.systems.url = "path:./flake/systems.nix";
  inputs.systems.flake = false;

  outputs = inputs @ {
    nosys,
    nixpkgs, # <---- This `nixpkgs` still has the `system` e.g. legacyPackages.${system}.zlib
    ...
  }: let outputs = import ./flake/out.nix;
     in nosys inputs outputs;
}
```

Just like a regular `outputs` functor:
```nix
# ./flake/out.nix
{
  self,
  nixpkgs, # <---- This `nixpkgs` has systems removed e.g. legacyPackages.zlib
  ...,
}: let
  inherit (nixpkgs.legacyPackages) pkgs;
in {
  # system dependant outputs
  devShells.default = self.devShells.dev;
  devShells.dev = pkgs.mkShell {
    buildInputs = with pkgs; [/* ... */];
  };

  # attributes prefixed with 1 (`_`) are kept system independant and the leading `_` is removed
  _lib.f = x: x;
  # attributes with 2 (`__`) underscores are passed through unmodified
  __functor = self: self.lib.f;

}
```


# Systems

The systems can be a Nix list of systems or a path to a nix file with one. This means if you wish,
you can even point to the file as a flake input, so that downstream can modify the systems with
`follows`.

`nosys` will use its own defaults if no flake input named `systems` exist. You can also
simply override systems as a list:
```nix
nosys (inputs' // {systems = ["x86_64-darwin"];}) # ({self, ...}:
```
## Cross Compilation

For advanced cases like cross-compilation the system's are still available in the usual place when
needing to reference a different system than the one currently being defined. 
