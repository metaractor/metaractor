{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
    dev-cli.url = "github:detaso/dev-cli";
    dev-cli.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        devenv.shells.default = let
          dev-cli = inputs.dev-cli.packages.${system}.default;
        in {
          # https://devenv.sh/reference/options/

          packages = with pkgs; [
            git
            nodejs-18_x
            yarn
            postgresql_14
            zlib
            zstd
            libiconv
            tmux
            tmuxPlugins.sensible
            tmuxPlugins.yank
            reattach-to-user-namespace
          ] ++ [
            dev-cli
          ];

          languages.ruby.enable = true;
          languages.ruby.bundler.enable = false;
          languages.ruby.version = "3.2.2";

          enterShell = ''
            export BUNDLE_BIN="$DEVENV_ROOT/.devenv/bin"
            export PATH="$DEVENV_PROFILE/bin:$DEVENV_ROOT/bin:$BUNDLE_BIN:$PATH"
            export BOOTSNAP_CACHE_DIR="$DEVENV_ROOT/.devenv/state"

            if [ ! -f ~/.tmux.conf ] && [ ! -f ~/.config/tmux/tmux.conf ] && [ -f "$DEVENV_ROOT/.overmind.tmux.conf" ]; then
              export OVERMIND_TMUX_CONFIG="$DEVENV_ROOT/.overmind.tmux.conf"
            fi
          '';

          env.OVERMIND_NO_PORT=1;
          env.OVERMIND_ANY_CAN_DIE=1;
          process.implementation = "overmind";

          env.RUBY_DEBUG_SOCK_DIR = "/tmp/";
        };
      };
    };
}
