{
  inputs.nosys.url = "path:../.";

  inputs.systems.url = "path:./flake/systems.nix";
  inputs.systems.flake = false;

  outputs = inputs @ {nosys, nixpkgs, ...}: let
    outputs = import ./flake/outputs.nix;
  in
    (nosys // {debug = true;}) inputs outputs;
}
