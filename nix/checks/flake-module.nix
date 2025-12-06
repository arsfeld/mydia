{self, ...}: {
  perSystem = {pkgs, ...}: {
    checks.mydia = pkgs.testers.runNixOSTest {
      name = "mydia";

      nodes.machine1 = {config, ...}: {
        imports = [self.nixosModules.default];

        config = {
          services = {
            mydia = {
              enable = true;

              secretKeyBaseFile = "/tmp/mydia/secret_key_base";

              database = {
                type = "postgres";
                uri = "postgres://mydia@localhost/mydia?sslmode=disabled";
                passwordFile = "/run/secrets/mydia/database_password";
              };
            };
          };
        };
      };

      # See the devmanual for available python methods:
      # https://nixos.org/manual/nixos/stable/#ssec-machine-objects
      testScript = ''
        import time

        machine.start()
        # machine.wait_for_unit("mydia.service")
        time.sleep(2)

        # assert machine.systemctl("is-active mydia") == "active"

        machine.succeed()
      '';
    };
  };
}
