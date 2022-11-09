{
  inputs.nosys.url = "github:divnix/nosys";

  inputs.systems.url = "path:./flake/systems.nix";
  inputs.systems.flake = false;

  outputs = inputs @ {nosys, ...}: let
    outputs = import ./flake/outputs.nix;
  in
    nosys inputs outputs;
}
