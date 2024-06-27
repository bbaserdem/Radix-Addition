# shell.nix
let
  pkgs = (import <nixpkgs> {});
in pkgs.mkShell {
  packages = with pkgs; [
    python313
    (poetry.override { python3 = python313; })
  ];
}
