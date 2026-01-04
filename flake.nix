{
  description = "Homelab";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        devshells.default = {
          packages = with pkgs; [cilium-cli fluxcd talosctl kubectl k9s kubernetes-helm nil renovate velero];
          commands = [
            {package = config.treefmt.build.wrapper;}
            {
              name = "tofu";
              command = ''
                TOFU=${pkgs.lib.getExe pkgs.opentofu}
                verb="$1"
                case $verb in
                  refresh|init|state|plan|apply|destroy|import|test|console|output) op run -- $TOFU "$@";;
                  *) $TOFU "$@";;
                esac
              '';
            }
          ];

          env = let
            nv = pkgs.lib.nameValuePair;
          in [
            (nv "TAILSCALE_API_KEY" "op://Private/Tailscale/api key")
            (nv "AWS_ACCESS_KEY_ID" "op://Private/Backblaze/application key/id")
            (nv "AWS_SECRET_ACCESS_KEY" "op://Private/Backblaze/application key/key")
          ];
        };
        treefmt = {
          programs.alejandra.enable = true;
          programs.terraform.enable = true;
        };
      };
    };
}
