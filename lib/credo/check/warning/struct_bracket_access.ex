defmodule Credo.Check.Warning.StructBracketAccess do
  @moduledoc """
  Detects bracket access on structs, which will fail at runtime.

  Structs do not implement the Access behavior by default, so using bracket
  notation like `struct[:field]` will raise `UndefinedFunctionError`.

  ## Examples

  ### Bad - will crash at runtime

      result[:title]  # If result is a struct, this fails
      user[:name]     # If user is a struct, this fails

  ### Good - use dot notation instead

      result.title    # Works for structs
      user.name       # Works for structs

  ## When to use bracket access

  Bracket access is safe for:
  - Plain maps: `%{name: "Alice"}[:name]`
  - Keyword lists: `[name: "Alice"][:name]`
  - Assigns: `socket.assigns[:user]`

  ## Exceptions

  This check will not flag bracket access on known safe patterns like:
  - `assigns[:key]`
  - `socket.assigns[:key]`
  - Map module functions: `Map.get(map, :key)`
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :warning

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # Traverse AST looking for bracket access patterns
  defp traverse(
         {{:., _, [Access, :get]}, meta,
          [
            {{:., _, [{variable_name, _, _}, _field]}, _, []},
            atom_key
          ]} = ast,
         issues,
         issue_meta
       )
       when is_atom(atom_key) and variable_name not in [:assigns, :socket] do
    # This catches patterns like: some_var.field[:key]
    # which suggests some_var.field is a struct being accessed with brackets
    issue = issue_for(issue_meta, meta[:line], atom_key, variable_name)
    {ast, [issue | issues]}
  end

  defp traverse(
         {{:., _, [Access, :get]}, meta, [{variable_name, _, _}, atom_key]} = ast,
         issues,
         issue_meta
       )
       when is_atom(atom_key) and variable_name not in [:assigns] do
    # This catches patterns like: variable[:key]
    # We exclude :assigns because socket.assigns[:key] is a common and safe pattern
    case safe_variable?(variable_name) do
      true ->
        {ast, issues}

      false ->
        issue = issue_for(issue_meta, meta[:line], atom_key, variable_name)
        {ast, [issue | issues]}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  # Variables that are known to be safe for bracket access
  defp safe_variable?(name) when is_atom(name) do
    name_str = Atom.to_string(name)

    # Allow variables ending in _map, _params, _attrs, etc.
    String.ends_with?(name_str, "_map") or
      String.ends_with?(name_str, "_params") or
      String.ends_with?(name_str, "_attrs") or
      String.ends_with?(name_str, "_opts") or
      String.ends_with?(name_str, "_config") or
      name in [:assigns, :params, :attrs, :opts, :config, :meta, :metadata]
  end

  defp safe_variable?(_), do: false

  defp issue_for(issue_meta, line_no, key, variable) do
    variable_name = format_variable(variable)

    format_issue(
      issue_meta,
      message:
        "Bracket access on #{variable_name}[:#{key}] may fail if #{variable_name} is a struct. " <>
          "Use #{variable_name}.#{key} for structs, or ensure #{variable_name} is a plain map.",
      line_no: line_no
    )
  end

  # Format variable name for display
  defp format_variable(variable) when is_atom(variable), do: to_string(variable)
  defp format_variable({:., _, [module, field]}), do: "#{format_variable(module)}.#{field}"
  defp format_variable({:__aliases__, _, modules}), do: Enum.join(modules, ".")
  defp format_variable(_), do: "variable"
end
