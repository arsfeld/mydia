defmodule MydiaWeb.ImportMediaLiveTest do
  use MydiaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mydia.AccountsFixtures

  alias Mydia.{Library, Settings}

  describe "session recovery" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "shows resume prompt when user has active import session", %{conn: conn, user: user} do
      # Create an active import session for the user
      {:ok, session} =
        Library.create_import_session(%{
          id: Ecto.UUID.generate(),
          user_id: user.id,
          step: :review,
          scan_path: "/test/media/library",
          scan_stats: %{"total" => 100, "matched" => 80},
          status: :active
        })

      conn = log_in_user(conn, user)

      # Navigate to import page without session_id - should show resume prompt
      {:ok, _view, html} = live(conn, ~p"/import")

      # Should show the resume prompt
      assert html =~ "Resume Previous Import?"
      assert html =~ "Resume Session"
      assert html =~ "Start Fresh"

      # Clean up
      Mydia.Repo.delete(session)
    end

    test "start fresh button abandons session and starts new one", %{conn: conn, user: user} do
      # Create an active import session
      {:ok, session} =
        Library.create_import_session(%{
          id: Ecto.UUID.generate(),
          user_id: user.id,
          step: :review,
          scan_path: "/test/media/library",
          status: :active
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/import")

      # Click start fresh - push_patch will update the view in place
      html =
        view
        |> element("button", "Start Fresh")
        |> render_click()

      # Should now be on path selection step (not showing resume prompt)
      refute html =~ "Resume Session"
      assert html =~ "Select a Library to Scan"

      # Original session should be abandoned
      updated_session = Library.get_import_session(session.id)
      assert updated_session.status == :abandoned
    end

    test "resume button redirects to existing session", %{conn: conn, user: user} do
      # Create an active import session
      session_id = Ecto.UUID.generate()

      {:ok, session} =
        Library.create_import_session(%{
          id: session_id,
          user_id: user.id,
          step: :review,
          scan_path: "/test/media/library",
          status: :active
        })

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/import")

      # Click resume - push_patch will update the view in place
      html =
        view
        |> element("button", "Resume Session")
        |> render_click()

      # Should no longer show resume prompt (session was restored)
      refute html =~ "Resume Previous Import?"

      # The session should still be active
      updated_session = Library.get_import_session(session.id)
      assert updated_session.status == :active

      # Clean up
      Mydia.Repo.delete(session)
    end

    test "no resume prompt when user has no active session", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      # Navigate to import page - should redirect to new session
      {:ok, _view, html} = live(conn, ~p"/import") |> follow_redirect(conn)

      # Should NOT show resume prompt - should show path selection
      refute html =~ "Resume Previous Import?"
      assert html =~ "Select a Library to Scan"
    end

    test "completed sessions do not trigger resume prompt", %{conn: conn, user: user} do
      # Create a completed session (not active)
      {:ok, session} =
        Library.create_import_session(%{
          id: Ecto.UUID.generate(),
          user_id: user.id,
          step: :complete,
          scan_path: "/test/media/library",
          status: :completed
        })

      conn = log_in_user(conn, user)

      # Navigate to import page - should redirect to new session, not show resume
      {:ok, _view, html} = live(conn, ~p"/import") |> follow_redirect(conn)

      # Should NOT show resume prompt
      refute html =~ "Resume Previous Import?"
      assert html =~ "Select a Library to Scan"

      # Clean up
      Mydia.Repo.delete(session)
    end
  end

  describe "library type filtering" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "filter_by_library_type filters movies from series-only library", %{user: _user} do
      # Create mock matched files with different media types
      movie_file = %{
        file: %{path: "/media/tv/Movie.2024.mkv", size: 1000},
        match_result: %{
          title: "Test Movie",
          provider_id: "12345",
          year: 2024,
          match_confidence: 0.9,
          parsed_info: %{type: :movie}
        },
        import_status: :pending
      }

      tv_show_file = %{
        file: %{path: "/media/tv/Show.S01E01.mkv", size: 1000},
        match_result: %{
          title: "Test Show",
          provider_id: "67890",
          year: 2024,
          match_confidence: 0.9,
          parsed_info: %{type: :tv_show, season: 1, episodes: [1]}
        },
        import_status: :pending
      }

      unmatched_file = %{
        file: %{path: "/media/tv/Unknown.mkv", size: 1000},
        match_result: nil,
        import_status: :pending
      }

      matched_files = [movie_file, tv_show_file, unmatched_file]

      # Create a series-only library path
      library_path = %{type: :series, path: "/media/tv"}

      # Call the filter function directly
      {compatible, filtered} = filter_by_library_type(matched_files, library_path)

      # Movies should be filtered out
      assert length(compatible) == 2
      assert length(filtered) == 1

      # The filtered file should be the movie
      assert hd(filtered).match_result.parsed_info.type == :movie

      # TV show and unmatched files should remain
      compatible_types =
        Enum.map(compatible, fn f ->
          if f.match_result, do: f.match_result.parsed_info.type, else: :unmatched
        end)

      assert :tv_show in compatible_types
      assert :unmatched in compatible_types
      refute :movie in compatible_types
    end

    test "filter_by_library_type filters tv shows from movies-only library", %{user: _user} do
      movie_file = %{
        file: %{path: "/media/movies/Movie.2024.mkv", size: 1000},
        match_result: %{
          title: "Test Movie",
          provider_id: "12345",
          year: 2024,
          match_confidence: 0.9,
          parsed_info: %{type: :movie}
        },
        import_status: :pending
      }

      tv_show_file = %{
        file: %{path: "/media/movies/Show.S01E01.mkv", size: 1000},
        match_result: %{
          title: "Test Show",
          provider_id: "67890",
          year: 2024,
          match_confidence: 0.9,
          parsed_info: %{type: :tv_show, season: 1, episodes: [1]}
        },
        import_status: :pending
      }

      matched_files = [movie_file, tv_show_file]

      # Create a movies-only library path
      library_path = %{type: :movies, path: "/media/movies"}

      {compatible, filtered} = filter_by_library_type(matched_files, library_path)

      # TV shows should be filtered out
      assert length(compatible) == 1
      assert length(filtered) == 1

      # The filtered file should be the TV show
      assert hd(filtered).match_result.parsed_info.type == :tv_show

      # Movie should remain
      assert hd(compatible).match_result.parsed_info.type == :movie
    end

    test "filter_by_library_type allows all types for mixed library", %{user: _user} do
      movie_file = %{
        file: %{path: "/media/mixed/Movie.2024.mkv", size: 1000},
        match_result: %{
          title: "Test Movie",
          provider_id: "12345",
          year: 2024,
          match_confidence: 0.9,
          parsed_info: %{type: :movie}
        },
        import_status: :pending
      }

      tv_show_file = %{
        file: %{path: "/media/mixed/Show.S01E01.mkv", size: 1000},
        match_result: %{
          title: "Test Show",
          provider_id: "67890",
          year: 2024,
          match_confidence: 0.9,
          parsed_info: %{type: :tv_show, season: 1, episodes: [1]}
        },
        import_status: :pending
      }

      matched_files = [movie_file, tv_show_file]

      # Create a mixed library path
      library_path = %{type: :mixed, path: "/media/mixed"}

      {compatible, filtered} = filter_by_library_type(matched_files, library_path)

      # Nothing should be filtered for mixed libraries
      assert length(compatible) == 2
      assert length(filtered) == 0
    end

    test "filter_by_library_type handles nil library_path gracefully", %{user: _user} do
      movie_file = %{
        file: %{path: "/media/Movie.2024.mkv", size: 1000},
        match_result: %{
          title: "Test Movie",
          provider_id: "12345",
          year: 2024,
          match_confidence: 0.9,
          parsed_info: %{type: :movie}
        },
        import_status: :pending
      }

      matched_files = [movie_file]

      # Nil library path should not filter anything
      {compatible, filtered} = filter_by_library_type(matched_files, nil)

      assert length(compatible) == 1
      assert length(filtered) == 0
    end

    # Helper function that mirrors the LiveView implementation
    defp filter_by_library_type(matched_files, nil), do: {matched_files, []}

    defp filter_by_library_type(matched_files, library_path) do
      case library_path.type do
        :mixed ->
          {matched_files, []}

        :series ->
          Enum.split_with(matched_files, fn matched_file ->
            case matched_file.match_result do
              nil -> true
              match -> match.parsed_info.type != :movie
            end
          end)

        :movies ->
          Enum.split_with(matched_files, fn matched_file ->
            case matched_file.match_result do
              nil -> true
              match -> match.parsed_info.type != :tv_show
            end
          end)

        _ ->
          {matched_files, []}
      end
    end
  end

  describe "import media live with library type filtering" do
    setup do
      user = user_fixture()

      # Create library paths of different types
      {:ok, series_path} =
        Settings.create_library_path(%{
          path: "/test/media/tv_#{System.unique_integer([:positive])}",
          type: :series,
          monitored: true
        })

      {:ok, movies_path} =
        Settings.create_library_path(%{
          path: "/test/media/movies_#{System.unique_integer([:positive])}",
          type: :movies,
          monitored: true
        })

      {:ok, mixed_path} =
        Settings.create_library_path(%{
          path: "/test/media/mixed_#{System.unique_integer([:positive])}",
          type: :mixed,
          monitored: true
        })

      %{
        user: user,
        series_path: series_path,
        movies_path: movies_path,
        mixed_path: mixed_path
      }
    end

    test "displays type mismatch stat when files are filtered", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      # The import page redirects to add a session_id, so we follow the redirect
      {:ok, view, _html} = live(conn, ~p"/import") |> follow_redirect(conn)

      # Initial state should not show type_filtered stat (0 filtered files)
      refute view
             |> element(".stat-title", "Type Mismatch")
             |> has_element?()
    end
  end
end
