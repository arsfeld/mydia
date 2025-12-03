{
  lib,
  self,
  ...
}: let
  inherit (lib) stringLength substring recursiveUpdate elemAt splitString foldl nameValuePair listToAttrs toInt;
  inherit (self.lib.pattern) while switch case exhaustive P;
in {
  parse = str: let
    when = kind: pattern: callback: let
      _p = "^${pattern}.*$";
    in
      case {
        input = P.match _p;
        result = {${kind} = null;};
      } ({
        input,
        result,
      }: let
        matches = lib.match _p input;
      in {
        input = substring (stringLength (elemAt matches 0)) (-1) input;
        result = recursiveUpdate result (foldl (cb: v: cb v) callback matches);
      });
  in
    {
      input = str;
      result = {href = str;};
    }
    |> while (state: (stringLength state.input) > 0) (
      state:
        switch state
        |> when "scheme" "(([a-z]+):/{0,2})" (_: scheme: {inherit scheme;})
        |> when "user" "(([^@:]+)(:([^@]+))?@)" (_: user: _: password: {inherit user password;})
        |> when "host" "((.+):([0-9]+)|(.+)*?)(/|\\?|#|$)" (host: hostname1: port: hostname2: _: {
          inherit host;
          hostName =
            if hostname1 != null
            then hostname1
            else if hostname2 != null
            then hostname2
            else null;
          port =
            if port != null
            then toInt port
            else null;
        })
        |> when "path" "((/[^/?#]+)*)" (path: _: {inherit path;})
        |> when "query" "(\\?([^=#&]+=[^=#&]+)*(&[^=#]+=[^=#&]+)*)" (query: _: _: {
          inherit query;
          queryParams =
            query
            |> substring 1 (-1)
            |> splitString "&"
            |> map (pair: pair |> splitString "=" |> (foldl (fn: arg: fn arg) nameValuePair))
            |> listToAttrs;
        })
        |> when "fragment" "(#.*)" (fragment: {inherit fragment;})
        |> exhaustive
    )
    |> ({result, ...}: result);
}
