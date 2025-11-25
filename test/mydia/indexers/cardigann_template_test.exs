defmodule Mydia.Indexers.CardigannTemplateTest do
  use ExUnit.Case, async: true

  alias Mydia.Indexers.CardigannTemplate

  describe "render/2" do
    test "renders simple keywords variable" do
      context = %{keywords: "Ubuntu 22.04"}
      assert {:ok, result} = CardigannTemplate.render("{{ .Keywords }}", context)
      assert result == "Ubuntu%2022.04"
    end

    test "renders config variables" do
      context = %{
        keywords: "test",
        config: %{"sort" => "seeders", "type" => "movie"}
      }

      assert {:ok, result} = CardigannTemplate.render("/search/{{ .Config.sort }}/", context)
      assert result == "/search/seeders/"
    end

    test "renders 'or' conditionals" do
      context = %{keywords: "", config: %{}}

      assert {:ok, result} =
               CardigannTemplate.render(
                 "{{ if or .Keywords .Config.apikey }}search{{ else }}latest{{ end }}",
                 context
               )

      assert result == "latest"
    end

    test "renders 'or' conditionals with truthy value" do
      context = %{keywords: "test", config: %{}}

      assert {:ok, result} =
               CardigannTemplate.render(
                 "{{ if or .Keywords .Config.apikey }}search{{ else }}latest{{ end }}",
                 context
               )

      assert result == "search"
    end

    test "renders query variables" do
      context = %{
        keywords: "Dune",
        query: %{season: 1, episode: 2}
      }

      assert {:ok, result} =
               CardigannTemplate.render("/{{ .Keywords }}/S{{ .Query.Season }}", context)

      assert result == "/Dune/S1"
    end

    test "renders re_replace function" do
      context = %{keywords: "test query"}

      assert {:ok, result} =
               CardigannTemplate.render(
                 "{{ re_replace .Keywords \" \" \"-\" }}",
                 context
               )

      assert result == "test-query"
    end

    test "renders join function" do
      context = %{categories: [2000, 2010, 2020]}

      assert {:ok, result} =
               CardigannTemplate.render(
                 "{{ join .Categories \",\" }}",
                 context
               )

      assert result == "2000,2010,2020"
    end

    test "handles nested conditionals with or" do
      context = %{
        keywords: "",
        query: %{album: nil, artist: nil}
      }

      template = "{{ if or .Query.Album .Query.Artist }}music{{ else }}other{{ end }}"
      assert {:ok, result} = CardigannTemplate.render(template, context)
      assert result == "other"
    end

    test "accesses default config values from settings" do
      context = %{
        keywords: "test",
        config: %{},
        settings: [%{name: "sort", default: "added"}]
      }

      assert {:ok, result} = CardigannTemplate.render("{{ .Config.sort }}", context)
      assert result == "added"
    end

    test "URL-encodes by default for paths" do
      context = %{keywords: "Dune: Part Two 2024"}
      assert {:ok, result} = CardigannTemplate.render("/search/{{ .Keywords }}/", context)
      assert result == "/search/Dune%3A%20Part%20Two%202024/"
    end

    test "does not URL-encode when url_encode: false for query params" do
      context = %{keywords: "Dune: Part Two 2024"}

      assert {:ok, result} =
               CardigannTemplate.render("{{ .Keywords }}", context, url_encode: false)

      assert result == "Dune: Part Two 2024"
    end
  end
end
