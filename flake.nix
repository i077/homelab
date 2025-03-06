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
          packages = with pkgs; [cilium-cli fluxcd talosctl kubectl k9s kubernetes-helm nil];
          commands = [
            {package = config.treefmt.build.wrapper;}
            {
              name = "tofu";
              command = ''
                TOFU=${pkgs.lib.getExe pkgs.opentofu}
                verb="$1"
                case $verb in
                  refresh|init|state|plan|apply|destroy|import|test|console) op run -- $TOFU "$@";;
                  *) $TOFU "$@";; 
                esac
              '';
            }
          ];

          env = [
            {name = "TAILSCALE_API_KEY"; value = "op://Private/Tailscale/api key";}
            {name = "AWS_ACCESS_KEY_ID"; value = "op://Private/Backblaze/application key/id";}
            {name = "AWS_SECRET_ACCESS_KEY"; value = "op://Private/Backblaze/application key/key";}
          ];
        };
        treefmt = {
          programs.alejandra.enable = true;
          programs.terraform.enable = true;
        };
      };
    };
}
