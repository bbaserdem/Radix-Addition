# file: flake.nix
{
  description = "Python application packaged using poetry2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
      in {
        packages = {
          myapp = mkPoetryApplication { projectDir = self; };
          default = self.packages.${system}.myapp;
        };

        # Shell for app dependencies
        #
        #   nix develop
        #
        # Use this shell for developing your app
        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.myapp ];
        };

        # Shell for poetry
        #
        #   nix develop .#poetry
        #
        # Use this shell for changes to pyproject.toml & poetry.lock
        devShells.poetry = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };
      }
    );
}
