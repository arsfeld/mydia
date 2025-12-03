{
  description = "Mydia - Self-hosted media management application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {
      inherit inputs;
    } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      imports = [
        ./nix/lib/flake-module.nix
        ./nix/devShells/flake-module.nix
        ./nix/packages/flake-module.nix
        ./nix/modules/flake-module.nix
        ./nix/checks/flake-module.nix
      ];

      perSystem = {
        lib,
        self',
        ...
      }: {
        checks = let
          packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
          devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
        in
          packages // devShells;
      };
    };
}
