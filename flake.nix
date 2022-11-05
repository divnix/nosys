{
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = top @ {utils, ...}: {
    __functor = self: self.lib.noSys;

    lib.noSys = inputs @ {systems ? utils.lib.defaultSystems, ...}: f: let
      systems' =
        if systems ? systems
        then systems.systems
        else if builtins.isPath systems || systems ? outPath
        then import systems
        else systems;
    in
      utils.lib.eachSystem systems' (sys: let
        f' = ins: let
          inputs = top.self.lib.deSys sys (builtins.removeAttrs ins ["self"]);
          self = top.self.lib.deSys sys (builtins.removeAttrs ins.self ["inputs"]);
        in
          # must be recombined after `deSys` to avoid infinite recursion
          f (inputs // {inherit self;});
      in
        f' inputs);
    lib.deSys = import ./desys.nix;
  };
}
