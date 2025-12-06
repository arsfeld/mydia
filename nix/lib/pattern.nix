{lib, ...}: let
  inherit (lib) isFunction isString isInt isAttrs attrsToList any all isList imap0 length elemAt;

  P = {
    # Wildcard
    _ = {
      __type = "pattern";
      __kind = "any wildcard";
      __functor = _: value: value != null;
    };
    string = {
      __type = "pattern";
      __kind = "any string";
      __functor = _: value: lib.isString value;
    };
    int = {
      __kind = "pattern";
      __type = "any int";
      __functor = _: value: isInt value;
    };

    # string
    match = pattern: {
      __type = "pattern";
      __kind = "regex string match";
      __functor = _: value: ((isString value) && (lib.match pattern value) != null);
    };

    # Escape hatch / custom matcher
    when = predicate: {
      __type = "pattern";
      __kind = "predicate";
      __functor = _: value: predicate value;
    };

    # Logical combinators
    not = pattern: {
      __type = "pattern";
      __kind = "not pattern";
      __functor = _: value: (isMatch pattern value) == false;
    };
    optional = pattern: {
      __type = "pattern";
      __kind = "optional / orNull pattern";
      __functor = _: value: isNull value || isMatch pattern value;
    };
    any = patternList: {
      __type = "pattern";
      __kind = "any of patterns";
      __functor = _: value: (any (pattern: isMatch pattern value) patternList);
    };
    all = patternList: {
      __type = "pattern";
      __kind = "all of patterns";
      __functor = _: value: (all (pattern: (isMatch pattern value)) patternList);
    };

    # Subpatterns
    list = pattern: {
      __type = "pattern";
      __kind = "permissive sublist";
      __functor = _: value:
        pattern
        |> imap0 (index: pattern: {inherit index pattern;})
        |> all (
          {
            index,
            pattern,
          }:
            isMatch pattern (elemAt value index)
        );
    };

    record = namePattern: valuePattern: {
      __type = "pattern";
      __kind = "record";
      __functor = _: value: throw "Not yet implemented";
    };
  };

  while = predicate: callback: var:
    if predicate var
    then while predicate callback (callback var)
    else var;

  isMatcher = subject: isFunction subject || (isAttrs subject && subject?__kind && subject.__type == "pattern");

  resolve = callbackOrLiteral: value:
    if isFunction callbackOrLiteral
    then callbackOrLiteral value
    else callbackOrLiteral;

  isMatch = pattern: value:
    if isMatcher pattern
    then pattern value
    # When a pattern is a set this assumes the value is a set as well
    else if isAttrs pattern && isAttrs value
    then
      pattern
      |> attrsToList
      |> all (
        pair: isMatch pair.value (value.${pair.name} or null)
      )
    # When a pattern is a list this assumes the value is a set as well
    else if isList pattern && isList value
    then (length pattern == length value) && ((P.list pattern) value)
    else pattern == value;
in {
  inherit P isMatch while;

  switch = source: {
    inherit source;
    state = "running";
  };

  case = pattern: callback: context:
    if (context.state != "matched" && isMatch pattern context.source)
    then
      context
      // {
        inherit callback;
        state = "matched";
      }
    else context;

  exhaustive = context:
    if context.state != "matched"
    then throw "Switch failed to match on '${builtins.toJSON context.source}'"
    else resolve context.callback context.source;
  otherwise = callbackOrLiteral: context:
    if context.state != "matched"
    then resolve callbackOrLiteral context.source
    else resolve context.callback context.source;
}
