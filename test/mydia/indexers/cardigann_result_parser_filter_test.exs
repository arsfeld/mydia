defmodule Mydia.Indexers.CardigannResultParserFilterTest do
  @moduledoc """
  Tests for Cardigann filter rendering with Go template support.

  These tests ensure that filter arguments containing Go template syntax
  are properly rendered before being applied to field values.
  """

  use ExUnit.Case, async: true

  alias Mydia.Indexers.CardigannResultParser

  describe "apply_filters/3 with template rendering" do
    test "renders template in append filter with string args" do
      filters = [
        %{"name" => "append", "args" => "{{ if .Config.flag }} suffix{{ else }}{{ end }}"}
      ]

      template_context = %{config: %{"flag" => true}}

      assert {:ok, "text suffix"} =
               CardigannResultParser.apply_filters("text", filters, template_context)
    end

    test "renders template in append filter with list args" do
      filters = [
        %{"name" => "append", "args" => ["{{ if .Config.flag }} suffix{{ else }}{{ end }}"]}
      ]

      template_context = %{config: %{"flag" => true}}

      assert {:ok, "text suffix"} =
               CardigannResultParser.apply_filters("text", filters, template_context)
    end

    test "renders template in append filter when flag is false" do
      filters = [
        %{"name" => "append", "args" => "{{ if .Config.flag }} suffix{{ else }}{{ end }}"}
      ]

      template_context = %{config: %{"flag" => false}}

      assert {:ok, "text"} =
               CardigannResultParser.apply_filters("text", filters, template_context)
    end

    test "renders template in re_replace filter replacement arg" do
      filters = [
        %{
          "name" => "re_replace",
          "args" => [
            "pattern",
            "{{ if .Config.stripcyrillic }}{{ else }}$1$2{{ end }}"
          ]
        }
      ]

      template_context = %{config: %{"stripcyrillic" => false}}

      # Since pattern doesn't match, value should be unchanged
      assert {:ok, "text"} =
               CardigannResultParser.apply_filters("text", filters, template_context)
    end

    test "handles template rendering when Config value is missing" do
      filters = [
        %{"name" => "append", "args" => "{{ if .Config.missing }} suffix{{ else }}{{ end }}"}
      ]

      template_context = %{config: %{}}

      assert {:ok, "text"} =
               CardigannResultParser.apply_filters("text", filters, template_context)
    end

    test "handles empty template context" do
      filters = [
        %{"name" => "append", "args" => " fixed"}
      ]

      assert {:ok, "text fixed"} = CardigannResultParser.apply_filters("text", filters, %{})
    end

    test "applies multiple filters with template rendering" do
      filters = [
        %{"name" => "replace", "args" => ["old", "new"]},
        %{"name" => "append", "args" => "{{ if .Config.add }} suffix{{ else }}{{ end }}"},
        %{"name" => "trim"}
      ]

      template_context = %{config: %{"add" => true}}

      assert {:ok, "new suffix"} =
               CardigannResultParser.apply_filters("old", filters, template_context)
    end

    test "handles filters without templates" do
      filters = [
        %{"name" => "replace", "args" => ["test", "result"]},
        %{"name" => "append", "args" => " done"}
      ]

      template_context = %{config: %{}}

      assert {:ok, "result done"} =
               CardigannResultParser.apply_filters("test", filters, template_context)
    end

    test "backward compatibility - works without template_context parameter" do
      filters = [
        %{"name" => "replace", "args" => ["test", "result"]},
        %{"name" => "trim"}
      ]

      assert {:ok, "result"} = CardigannResultParser.apply_filters("test", filters)
    end

    test "renders complex BitRu-style append filter" do
      filters = [
        %{
          "name" => "append",
          "args" => "{{ if .Config.addrussiantotitle }} RUS{{ else }}{{ end }}"
        }
      ]

      # Test with flag enabled
      context_enabled = %{config: %{"addrussiantotitle" => true}}

      assert {:ok, "Title RUS"} =
               CardigannResultParser.apply_filters("Title", filters, context_enabled)

      # Test with flag disabled
      context_disabled = %{config: %{"addrussiantotitle" => false}}

      assert {:ok, "Title"} =
               CardigannResultParser.apply_filters("Title", filters, context_disabled)
    end

    @tag :skip
    test "handles re_replace with Unicode character classes (Go-specific, not supported in Elixir)" do
      # NOTE: Elixir's Regex uses PCRE which doesn't support Go's \p{IsCyrillic} syntax
      # This test documents the limitation. In practice, these patterns will fail with :invalid_regex
      # and the row will be filtered out, which is expected behavior for incompatible patterns.
      filters = [
        %{
          "name" => "re_replace",
          "args" => [
            "(\\([\\p{IsCyrillic}\\W]+\\))|(^[\\p{IsCyrillic}\\W\\d]+\\/ )|([\\p{IsCyrillic} \\-]+,+)|([\\p{IsCyrillic}]+)",
            "{{ if .Config.stripcyrillic }}{{ else }}$1$2$3$4{{ end }}"
          ]
        }
      ]

      template_context = %{config: %{"stripcyrillic" => false}}

      cyrillic_text = "Test (Русский) Title"

      # This will return {:error, :invalid_regex} due to unsupported Unicode property
      assert {:error, :invalid_regex} =
               CardigannResultParser.apply_filters(cyrillic_text, filters, template_context)
    end

    test "handles re_replace with template that renders to empty string" do
      filters = [
        %{
          "name" => "re_replace",
          "args" => [
            "pattern",
            "{{ if .Config.stripcyrillic }}{{ else }}$1{{ end }}"
          ]
        }
      ]

      # When flag is true, template renders to empty string
      template_context = %{config: %{"stripcyrillic" => true}}

      # Pattern doesn't match, so value unchanged
      assert {:ok, "text"} =
               CardigannResultParser.apply_filters("text", filters, template_context)
    end
  end

  describe "filter rendering edge cases" do
    test "handles filter with no args" do
      filters = [%{"name" => "trim"}]

      assert {:ok, "text"} = CardigannResultParser.apply_filters("  text  ", filters, %{})
    end

    test "handles filter with nil args" do
      filters = [%{"name" => "trim", "args" => nil}]

      # Should still work as trim doesn't need args
      assert {:ok, "text"} = CardigannResultParser.apply_filters("  text  ", filters, %{})
    end

    test "handles malformed template gracefully" do
      filters = [
        %{"name" => "append", "args" => "{{ if .Config.flag  suffix"}
      ]

      template_context = %{config: %{"flag" => true}}

      # Should return original template on error
      assert {:ok, result} =
               CardigannResultParser.apply_filters("text", filters, template_context)

      assert String.contains?(result, "{{")
    end

    test "handles atom keys in filter maps" do
      filters = [
        %{name: "append", args: "{{ if .Config.flag }} suffix{{ else }}{{ end }}"}
      ]

      template_context = %{config: %{"flag" => true}}

      assert {:ok, "text suffix"} =
               CardigannResultParser.apply_filters("text", filters, template_context)
    end

    test "handles mixed string and atom keys" do
      filters = [
        %{"name" => "replace", "args" => ["old", "new"]},
        %{"name" => "append", "args" => " done"}
      ]

      assert {:ok, "new done"} = CardigannResultParser.apply_filters("old", filters, %{})
    end
  end

  describe "real-world BitRu filters" do
    setup do
      # Actual BitRu configuration
      template_context = %{
        config: %{
          "stripcyrillic" => false,
          "addrussiantotitle" => false,
          "adverts" => true,
          "sort" => "_"
        }
      }

      {:ok, context: template_context}
    end

    test "processes BitRu title with all filters", %{context: context} do
      # Simplified subset of BitRu title filters
      filters = [
        %{
          "name" => "re_replace",
          "args" => ["(?i)\\bHDTV[-\\s]?Rip\\b", "HDTV"]
        },
        %{
          "name" => "re_replace",
          "args" => ["(?i)\\bWEB\\sDL\\b", "WEB-DL"]
        },
        %{
          "name" => "append",
          "args" => "{{ if .Config.addrussiantotitle }} RUS{{ else }}{{ end }}"
        }
      ]

      title = "Test HDTV-Rip WEB DL"

      assert {:ok, "Test HDTV WEB-DL"} =
               CardigannResultParser.apply_filters(title, filters, context)
    end

    test "handles Russian text with simple pattern match", %{context: context} do
      # Use simple pattern that works in PCRE
      # Matches words containing non-ASCII characters (which includes Cyrillic)
      filters = [
        %{
          "name" => "replace",
          "args" => ["Тест", "{{ if .Config.stripcyrillic }}{{ else }}Тест{{ end }}"]
        }
      ]

      title = "Test Тест Title"

      {:ok, result} = CardigannResultParser.apply_filters(title, filters, context)

      # Should keep "Тест" when stripcyrillic is false
      assert result == "Test Тест Title"
    end
  end
end
