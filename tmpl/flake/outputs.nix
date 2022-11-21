{self, nixpkgs, ...}: {
  packages = {inherit (nixpkgs.legacyPackages) hello;};
}
