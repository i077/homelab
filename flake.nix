{
  description = "Homelab";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { config, pkgs, ... }:
        {
          devshells.default = {
            packages = with pkgs; [fluxcd opentofu talosctl kubectl k9s kubernetes-helm nil];
            commands = [
              { package = config.treefmt.build.wrapper; }
            ];
          };
          treefmt = {
            projectRootFile = ".git/config";
            programs.nixfmt.enable = true;
          };
        };
    };
}
