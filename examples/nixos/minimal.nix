# Minimal NixOS configuration for Mydia
#
# Usage in your flake.nix:
#   inputs.mydia.url = "github:owner/mydia";
#   modules = [ mydia.nixosModules.default ./mydia.nix ];
#
# Generate secret: openssl rand -base64 48 > /run/secrets/mydia/secret_key_base

{ config, pkgs, ... }:

{
  services.mydia = {
    enable = true;
    package = pkgs.mydia;

    # Web interface
    host = "localhost";
    port = 4000;

    # Required: path to file containing SECRET_KEY_BASE
    secretKeyBaseFile = "/run/secrets/mydia/secret_key_base";

    # Media libraries (optional but recommended)
    mediaLibraries = [
      "/mnt/media/movies"
      "/mnt/media/tv"
    ];
  };
}
