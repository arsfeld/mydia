{lib, ...} @ args: {
  flake.lib = {
    pattern = import ./pattern.nix args;
    url = import ./url.nix args;
  };
}
