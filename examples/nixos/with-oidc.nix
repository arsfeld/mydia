# NixOS configuration with OIDC authentication
#
# This example shows how to configure Mydia with OIDC
# authentication using agenix for secrets management.
#
# Usage in your flake.nix:
#   inputs.mydia.url = "github:owner/mydia";
#   modules = [ mydia.nixosModules.default ./mydia.nix ];

{ config, pkgs, ... }:

{
  # Secrets managed by agenix
  age.secrets = {
    mydia-secret-key.file = ./secrets/mydia-secret-key.age;
    mydia-guardian-secret.file = ./secrets/mydia-guardian-secret.age;
    mydia-oidc-client-id.file = ./secrets/mydia-oidc-client-id.age;
    mydia-oidc-client-secret.file = ./secrets/mydia-oidc-client-secret.age;
  };

  services.mydia = {
    enable = true;
    package = pkgs.mydia;

    # Web server
    host = "mydia.example.com";
    port = 4000;
    listenAddress = "127.0.0.1";

    # Secrets
    secretKeyBaseFile = config.age.secrets.mydia-secret-key.path;
    guardianSecretKeyFile = config.age.secrets.mydia-guardian-secret.path;

    # Media libraries
    mediaLibraries = [
      "/mnt/media/movies"
      "/mnt/media/tv"
    ];

    # OIDC Authentication
    oidc = {
      enable = true;

      # Authentik example
      issuer = "https://auth.example.com/application/o/mydia/";
      clientIdFile = config.age.secrets.mydia-oidc-client-id.path;
      clientSecretFile = config.age.secrets.mydia-oidc-client-secret.path;
      scopes = [ "openid" "profile" "email" ];

      # Optional: custom discovery document URI (usually auto-detected)
      # discoveryDocumentUri = "https://auth.example.com/.well-known/openid-configuration";
    };
  };

  # Nginx reverse proxy with SSL
  services.nginx = {
    enable = true;
    virtualHosts."mydia.example.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:4000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  # ACME for Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };
}
