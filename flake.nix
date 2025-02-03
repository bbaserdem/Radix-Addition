# file: flake.nix
{
  description = "Python application packaged using uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    uv2nix,
    pyproject-nix,
    pyproject-build-systems,
    ...
  } @ inputs: let
    # Get lib functions
    inherit (nixpkgs) lib;

    # Load a uv workspace from workspace root
    workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

    # Create package overlay from workspace
    overlay = workspace.mkPyprojectOverlay {
      sourcePreference = "wheel";
    };

    # Extend overlay with build fixups
    # - https://pyproject-nix.github.io/uv2nix/FAQ.html
    pyprojectOverrides = _final: _prev: {
    };

    # Architectures; we are just using x86_64-linux
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    # Use python 3.12
    python = pkgs.python312;

    # Make package set
    pythonSet =
      # Use base package set from pyproject.nix builders
      (pkgs.callPackage pyproject-nix.build.packages {
        inherit python;
      })
      .overrideScope (lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        overlay
        pyprojectOverrides
      ]);
  in {
    # Formatting for the flake
    formatter.x86_64-linux = pkgs.alejandra;

    # Package a virtual environment as main application
    packages.x86_64-linux.default =
      pythonSet.mkVirtualEnv
      "radix-addition-env"
      workspace.deps.default;

    # Make us runnable with nix run
    apps.x86_64-linux = {
      default = {
        type = "app";
        program = "${self.packages.x86_64-linux.default}/bin/radix-addition";
      };
    };

    # The impure shell to do virtualenv workflow
    devShells.x86_64-linux = {
      # Undo the dependency leakage by nix
      impure = pkgs.mkShell {
        packages = [
          python
          pkgs.uv
        ];
        env =
          {
            UV_PYTHON_DOWNLOADS = "never";
            UV_PYTHON = python.interpreter;
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
          };
        shellHook = ''
          unset PYTHONPATH
        '';
      };
    };
  };
}
