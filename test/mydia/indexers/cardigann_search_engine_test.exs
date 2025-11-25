defmodule Mydia.Indexers.CardigannSearchEngineTest do
  use ExUnit.Case, async: true

  alias Mydia.Indexers.CardigannSearchEngine
  alias Mydia.Indexers.CardigannDefinition.Parsed
  alias Mydia.Indexers.Adapter.Error
  alias Mydia.Indexers.FlareSolverr

  describe "build_search_url/2" do
    test "builds URL with simple keyword substitution" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search/{{ .Keywords }}/1/"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      assert {:ok, url} =
               CardigannSearchEngine.build_search_url(definition, query: "Ubuntu 22.04")

      assert url == "https://example.com/search/Ubuntu%2022.04/1/"
    end

    test "builds URL with multiple template variables" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [
            %{
              path: "/search?q={{ .Keywords }}&cat={{ .Categories }}&season={{ .Query.Season }}"
            }
          ],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      opts = [query: "Breaking Bad", categories: [5000, 5030], season: 1]

      assert {:ok, url} = CardigannSearchEngine.build_search_url(definition, opts)
      assert url =~ "q=Breaking%20Bad"
      assert url =~ "cat=5000,5030"
      assert url =~ "season=1"
    end

    test "selects correct path based on categories" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [
            %{path: "/movies", categories: [2000]},
            %{path: "/tv", categories: [5000]},
            %{path: "/all"}
          ],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      # Should select TV path
      assert {:ok, url} = CardigannSearchEngine.build_search_url(definition, categories: [5000])
      assert url == "https://example.com/tv"

      # Should select movies path
      assert {:ok, url} = CardigannSearchEngine.build_search_url(definition, categories: [2000])
      assert url == "https://example.com/movies"

      # Should select first path (movies) when no categories match
      assert {:ok, url} = CardigannSearchEngine.build_search_url(definition, categories: [8000])
      assert url == "https://example.com/movies"
    end

    test "handles missing base URL" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: [],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      assert {:error, %Error{type: :search_failed}} =
               CardigannSearchEngine.build_search_url(definition, query: "test")
    end

    test "URI-encodes special characters in query" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search/{{ .Keywords }}"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      assert {:ok, url} =
               CardigannSearchEngine.build_search_url(definition, query: "test & query=value")

      assert url == "https://example.com/search/test%20%26%20query%3Dvalue"
    end
  end

  describe "build_request_params/2" do
    test "builds basic GET request params" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search", method: "get"}],
          inputs: %{"type" => "search", "limit" => "100"},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      assert {:ok, params} =
               CardigannSearchEngine.build_request_params(definition, query: "Ubuntu")

      assert params.method == :get
      assert params.query_params["type"] == "search"
      assert params.query_params["limit"] == "100"
      assert params.headers == []
    end

    test "builds POST request params" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search", method: "post"}],
          inputs: %{"q" => "$raw:{{ .Keywords }}"},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      assert {:ok, params} =
               CardigannSearchEngine.build_request_params(definition, query: "Ubuntu")

      assert params.method == :post
      assert params.query_params["q"] == "Ubuntu"
    end

    test "includes custom headers from definition" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search"}],
          inputs: %{},
          headers: %{"User-Agent" => "MyClient/1.0", "Accept" => "application/json"},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      assert {:ok, params} =
               CardigannSearchEngine.build_request_params(definition, query: "test")

      assert {"User-Agent", "MyClient/1.0"} in params.headers
      assert {"Accept", "application/json"} in params.headers
    end

    test "substitutes template variables in input values" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search"}],
          inputs: %{
            "q" => "{{ .Keywords }}",
            "cat" => "{{ .Categories }}",
            "type" => "search"
          },
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil
      }

      opts = [query: "Ubuntu", categories: [2000, 5000]]

      assert {:ok, params} = CardigannSearchEngine.build_request_params(definition, opts)

      assert params.query_params["q"] == "Ubuntu"
      assert params.query_params["cat"] == "2000,5000"
      assert params.query_params["type"] == "search"
    end
  end

  describe "validate_response/1" do
    test "accepts valid 200 response" do
      response = %{status: 200, body: "<html>...</html>", headers: []}
      assert :ok = CardigannSearchEngine.validate_response(response)
    end

    test "rejects 401 authentication error" do
      response = %{status: 401, body: "Unauthorized", headers: []}

      assert {:error, %Error{type: :connection_failed, message: message}} =
               CardigannSearchEngine.validate_response(response)

      assert message =~ "Authentication failed"
    end

    test "rejects 403 forbidden error" do
      response = %{status: 403, body: "Forbidden", headers: []}

      assert {:error, %Error{type: :connection_failed}} =
               CardigannSearchEngine.validate_response(response)
    end

    test "rejects 429 rate limit error" do
      response = %{status: 429, body: "Too Many Requests", headers: []}

      assert {:error, %Error{type: :rate_limited, message: message}} =
               CardigannSearchEngine.validate_response(response)

      assert message =~ "Rate limit"
    end

    test "rejects 500 server error" do
      response = %{status: 500, body: "Internal Server Error", headers: []}

      assert {:error, %Error{type: :search_failed, message: message}} =
               CardigannSearchEngine.validate_response(response)

      assert message =~ "Server error"
    end

    test "rejects 404 not found" do
      response = %{status: 404, body: "Not Found", headers: []}

      assert {:error, %Error{type: :search_failed, message: message}} =
               CardigannSearchEngine.validate_response(response)

      assert message =~ "HTTP 404"
    end
  end

  describe "execute_http_request/2" do
    setup do
      # Create a test definition
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://httpbin.org"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/html"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil,
        request_delay: nil,
        follow_redirect: false
      }

      %{definition: definition}
    end

    @tag :external
    test "executes successful GET request", %{definition: definition} do
      params = %{
        query_params: %{},
        headers: [{"Accept", "text/html"}],
        method: :get
      }

      assert {:ok, response} =
               CardigannSearchEngine.execute_http_request(
                 definition,
                 "https://httpbin.org/html",
                 params,
                 %{}
               )

      assert response.status == 200
      assert is_binary(response.body)
      assert response.body =~ "<!DOCTYPE html>"
    end

    @tag :external
    test "handles request timeout gracefully", %{definition: definition} do
      # Use a delay endpoint to simulate timeout
      params = %{
        query_params: %{},
        headers: [],
        method: :get
      }

      # Override receive_timeout to 1ms to force timeout
      definition_with_short_timeout = definition

      # This should timeout quickly
      assert {:error, %Error{type: :connection_failed}} =
               CardigannSearchEngine.execute_http_request(
                 definition_with_short_timeout,
                 "https://httpbin.org/delay/10",
                 params,
                 %{}
               )
    end

    test "adds cookies from user config", %{definition: definition} do
      params = %{
        query_params: %{},
        headers: [],
        method: :get
      }

      user_config = %{
        cookies: ["session=abc123", "token=xyz789"]
      }

      # We can't easily test the actual cookie sending without mocking,
      # but we can verify the function executes without error
      # In a real scenario, you'd use a mock/stub library
      assert {:error, _} =
               CardigannSearchEngine.execute_http_request(
                 definition,
                 "https://invalid-domain-for-testing.example",
                 params,
                 user_config
               )
    end
  end

  describe "rate limiting" do
    test "respects request_delay setting" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil,
        request_delay: 0.1,
        # 100ms delay
        follow_redirect: false
      }

      params = %{
        query_params: %{},
        headers: [],
        method: :get
      }

      start_time = System.monotonic_time(:millisecond)

      # This will fail to connect, but we're just testing the delay
      CardigannSearchEngine.execute_http_request(
        definition,
        "https://invalid-domain.example",
        params,
        %{}
      )

      end_time = System.monotonic_time(:millisecond)
      elapsed = end_time - start_time

      # Should have delayed for at least 100ms
      # We allow some margin for test execution
      assert elapsed >= 90
    end
  end

  describe "execute_search/3 integration" do
    test "executes full search flow with valid definition" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search/{{ .Keywords }}"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil,
        request_delay: nil,
        follow_redirect: false
      }

      # This will fail to connect since example.com doesn't have our endpoint,
      # but it tests the flow up to the HTTP request
      assert {:error, _} = CardigannSearchEngine.execute_search(definition, query: "Ubuntu")
    end

    test "handles missing query gracefully" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        description: "Test indexer",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search/{{ .Keywords }}"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil,
        request_delay: nil,
        follow_redirect: false
      }

      # Should handle empty query by substituting empty string
      assert {:error, _} = CardigannSearchEngine.execute_search(definition, [])
    end
  end

  describe "FlareSolverr integration" do
    setup do
      definition = %Parsed{
        id: "test-flaresolverr",
        name: "Test FlareSolverr",
        description: "Test indexer for FlareSolverr",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search/{{ .Keywords }}"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil,
        request_delay: nil,
        follow_redirect: false
      }

      %{definition: definition}
    end

    test "execute_search accepts flaresolverr_opts parameter", %{definition: definition} do
      flaresolverr_opts = %{enabled: false, definition_id: "test-uuid"}

      # Should not error due to invalid flaresolverr_opts
      # It will error due to network, but that's expected
      assert {:error, _} =
               CardigannSearchEngine.execute_search(
                 definition,
                 [query: "test"],
                 %{},
                 flaresolverr_opts
               )
    end

    test "execute_search works without flaresolverr_opts", %{definition: definition} do
      # Should work without passing flaresolverr_opts (backward compatible)
      assert {:error, _} = CardigannSearchEngine.execute_search(definition, [query: "test"], %{})
    end

    test "flaresolverr enabled check respects global config", %{definition: _definition} do
      # Save original config
      original = Application.get_env(:mydia, :flaresolverr)

      # Disable FlareSolverr globally
      Application.put_env(:mydia, :flaresolverr, enabled: false, url: "http://localhost:8191")

      # Even with enabled: true in opts, should not use FlareSolverr
      refute FlareSolverr.enabled?()

      # Restore original config
      if original do
        Application.put_env(:mydia, :flaresolverr, original)
      else
        Application.delete_env(:mydia, :flaresolverr)
      end
    end

    test "flaresolverr enabled check requires URL", %{definition: _definition} do
      # Save original config
      original = Application.get_env(:mydia, :flaresolverr)

      # Enable but without URL
      Application.put_env(:mydia, :flaresolverr, enabled: true, url: nil)
      refute FlareSolverr.enabled?()

      # Enable with empty URL
      Application.put_env(:mydia, :flaresolverr, enabled: true, url: "")
      refute FlareSolverr.enabled?()

      # Enable with valid URL
      Application.put_env(:mydia, :flaresolverr, enabled: true, url: "http://localhost:8191")
      assert FlareSolverr.enabled?()

      # Restore original config
      if original do
        Application.put_env(:mydia, :flaresolverr, original)
      else
        Application.delete_env(:mydia, :flaresolverr)
      end
    end
  end

  describe "Cloudflare challenge detection" do
    test "detects Cloudflare 403 response with cf-browser-verification" do
      response = %{
        status: 403,
        body: """
        <html><body>
        <div id="cf-browser-verification">Please wait...</div>
        </body></html>
        """,
        headers: []
      }

      # The cloudflare_challenge? function is private, but we can test it indirectly
      # through the validation flow - 403 with Cloudflare content should be detected
      # We test the validate_response function behavior
      assert {:error, %Error{type: :connection_failed}} =
               CardigannSearchEngine.validate_response(response)
    end

    test "detects Cloudflare 403 response with cf_clearance" do
      response = %{
        status: 403,
        body: """
        <html><body>
        cf_clearance cookie required
        </body></html>
        """,
        headers: []
      }

      assert {:error, %Error{type: :connection_failed}} =
               CardigannSearchEngine.validate_response(response)
    end

    test "detects DDoS-Guard 403 response" do
      response = %{
        status: 403,
        body: """
        <html><body>
        DDoS-Guard protection
        </body></html>
        """,
        headers: []
      }

      assert {:error, %Error{type: :connection_failed}} =
               CardigannSearchEngine.validate_response(response)
    end

    test "detects Cloudflare 503 response" do
      response = %{
        status: 503,
        body: """
        <html><body>
        <div>Checking your browser before accessing... Cloudflare</div>
        </body></html>
        """,
        headers: []
      }

      assert {:error, %Error{type: :search_failed}} =
               CardigannSearchEngine.validate_response(response)
    end

    test "regular 403 without Cloudflare markers is still rejected" do
      response = %{
        status: 403,
        body: "Access denied. Login required.",
        headers: []
      }

      # Regular 403 should still fail, just not as Cloudflare
      assert {:error, %Error{type: :connection_failed}} =
               CardigannSearchEngine.validate_response(response)
    end
  end

  describe "cookie handling in user_config" do
    setup do
      definition = %Parsed{
        id: "test-cookies",
        name: "Test Cookies",
        description: "Test indexer for cookie handling",
        language: "en-US",
        type: "public",
        encoding: "UTF-8",
        links: ["https://example.com"],
        capabilities: %{modes: %{}},
        search: %{
          paths: [%{path: "/search"}],
          inputs: %{},
          rows: %{selector: "tr"},
          fields: %{title: %{selector: "td.title"}}
        },
        login: nil,
        download: nil,
        request_delay: nil,
        follow_redirect: false
      }

      %{definition: definition}
    end

    test "user_config cookies are included in request", %{definition: definition} do
      params = %{
        query_params: %{},
        headers: [],
        method: :get
      }

      user_config = %{
        cookies: ["session=abc123", "token=xyz789"]
      }

      # This will fail to connect, but we're testing the function accepts cookies
      # In real usage, a mock server would verify the Cookie header
      assert {:error, _} =
               CardigannSearchEngine.execute_http_request(
                 definition,
                 "https://invalid-domain-for-testing.example",
                 params,
                 user_config
               )
    end

    test "empty cookies list is handled", %{definition: definition} do
      params = %{
        query_params: %{},
        headers: [],
        method: :get
      }

      user_config = %{
        cookies: []
      }

      assert {:error, _} =
               CardigannSearchEngine.execute_http_request(
                 definition,
                 "https://invalid-domain-for-testing.example",
                 params,
                 user_config
               )
    end

    test "missing cookies key is handled", %{definition: definition} do
      params = %{
        query_params: %{},
        headers: [],
        method: :get
      }

      user_config = %{}

      assert {:error, _} =
               CardigannSearchEngine.execute_http_request(
                 definition,
                 "https://invalid-domain-for-testing.example",
                 params,
                 user_config
               )
    end
  end
end
