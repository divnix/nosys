{
  outputs = {self}: {
    __functor = self: self.lib.noSys;

    lib.noSys = inputs @ {systems ? import ./systems.nix, ...}: f: let
      systems' =
        if builtins.isPath systems || systems ? outPath
        then import systems
        else (f inputs).__systems or systems;
    in
      self.lib.eachSys systems' (sys: let
        f' = inputs: let
          inputs' = self.lib.deSys sys (builtins.removeAttrs inputs ["self"]);
          self' = self.lib.deSys sys (builtins.removeAttrs inputs.self ["inputs"]);
        in
          # must be recombined after `deSys` to avoid infinite recursion
          builtins.removeAttrs (f (inputs' // {self = self';})) ["__systems"];
      in
        f' inputs);

    lib.deSys = import ./desys.nix;
    lib.eachSys = import ./eachSys.nix;
  };
}
