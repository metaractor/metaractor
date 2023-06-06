{ pkgs, ... }:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
  ];

  # https://devenv.sh/languages/
  languages.ruby.enable = true;
  # Uses bobvanderlinden/nixpkgs-ruby to supply any version of ruby
  languages.ruby.versionFile = ./.ruby-version;

  enterShell = ''
    export BUNDLE_BIN="$DEVENV_ROOT/.devenv/bin"
    export PATH="$DEVENV_PROFILE/bin:$DEVENV_ROOT/bin:$BUNDLE_BIN:$PATH"
    export BOOTSNAP_CACHE_DIR="$DEVENV_ROOT/.devenv/state"
  '';

  # The unix socket path can't be "too long".
  # Make sure it's short for when we need it.
  env.RUBY_DEBUG_SOCK_DIR = "/tmp/";

  # See full reference at https://devenv.sh/reference/options/
}
