defmodule MydiaWeb.AdminConfigLive.IndexerLibraryTest do
  use MydiaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mydia.AccountsFixtures
  import Mydia.IndexersFixtures

  alias Mydia.Indexers

  describe "mount" do
    setup :register_and_log_in_admin

    test "redirects to config when feature flag is disabled", %{conn: conn} do
      # Temporarily disable feature flag
      set_cardigann_feature_flag(false)

      # When feature flag is disabled, mount should redirect
      assert {:error, {:live_redirect, %{to: "/admin/config"}}} =
               live(conn, ~p"/admin/config/indexers/library")
    end

    test "displays indexer library when feature flag is enabled", %{conn: conn} do
      # Enable feature flag
      set_cardigann_feature_flag(true)

      {:ok, _view, html} = live(conn, ~p"/admin/config/indexers/library")
      assert html =~ "Cardigann Indexer Library"
      assert html =~ "Total Indexers"
    end

    test "displays stats correctly", %{conn: conn} do
      set_cardigann_feature_flag(true)

      # Create some test definitions
      cardigann_definition_fixture(%{enabled: true})
      cardigann_definition_fixture(%{enabled: false})

      {:ok, _view, html} = live(conn, ~p"/admin/config/indexers/library")
      assert html =~ "Total Indexers"
      assert html =~ "Enabled"
      assert html =~ "Disabled"
    end
  end

  describe "filters" do
    setup :register_and_log_in_admin
    setup :enable_cardigann_feature_flag

    test "filters by type", %{conn: conn} do
      public_def = cardigann_definition_fixture(%{name: "Public Indexer", type: "public"})

      private_def =
        cardigann_definition_fixture(%{name: "Private Indexer", type: "private"})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      # Filter by public
      html =
        view
        |> element("select[name='type']")
        |> render_change(%{"type" => "public"})

      assert html =~ public_def.name
      refute html =~ private_def.name
    end

    test "filters by enabled status", %{conn: conn} do
      enabled_def = cardigann_definition_fixture(%{name: "Enabled Indexer", enabled: true})

      disabled_def =
        cardigann_definition_fixture(%{name: "Disabled Indexer", enabled: false})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      # Filter by enabled
      html =
        view
        |> element("select[name='enabled']")
        |> render_change(%{"enabled" => "enabled"})

      assert html =~ enabled_def.name
      refute html =~ disabled_def.name
    end

    test "searches by name", %{conn: conn} do
      indexer1 = cardigann_definition_fixture(%{name: "RARBG"})
      indexer2 = cardigann_definition_fixture(%{name: "1337x"})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      # Search for RARBG
      html =
        view
        |> element("form#search-form")
        |> render_change(%{"search" => %{"query" => "RARBG"}})

      assert html =~ indexer1.name
      refute html =~ indexer2.name
    end
  end

  describe "toggle indexer" do
    setup :register_and_log_in_admin
    setup :enable_cardigann_feature_flag

    test "enables a disabled indexer", %{conn: conn} do
      definition = cardigann_definition_fixture(%{enabled: false})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      view
      |> element("input[type='checkbox'][phx-value-id='#{definition.id}']")
      |> render_click()

      # Verify the indexer is now enabled
      updated_definition = Indexers.get_cardigann_definition!(definition.id)
      assert updated_definition.enabled
    end

    test "disables an enabled indexer", %{conn: conn} do
      definition = cardigann_definition_fixture(%{enabled: true})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      view
      |> element("input[type='checkbox'][phx-value-id='#{definition.id}']")
      |> render_click()

      # Verify the indexer is now disabled
      updated_definition = Indexers.get_cardigann_definition!(definition.id)
      refute updated_definition.enabled
    end
  end

  describe "configure indexer" do
    setup :register_and_log_in_admin
    setup :enable_cardigann_feature_flag

    test "opens configuration modal for private indexers", %{conn: conn} do
      definition = cardigann_definition_fixture(%{type: "private", name: "Private Site"})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      html =
        view
        |> element("button[phx-click='configure_indexer'][phx-value-id='#{definition.id}']")
        |> render_click()

      assert html =~ "Configure Private Site"
      assert html =~ "Username"
      assert html =~ "Password"
    end

    test "saves configuration", %{conn: conn} do
      definition = cardigann_definition_fixture(%{type: "private"})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      # Open modal
      view
      |> element("button[phx-click='configure_indexer'][phx-value-id='#{definition.id}']")
      |> render_click()

      # Submit config
      view
      |> element("form#config-form")
      |> render_submit(%{
        "config" => %{
          "username" => "testuser",
          "password" => "testpass"
        }
      })

      # Verify config was saved
      updated_definition = Indexers.get_cardigann_definition!(definition.id)
      assert updated_definition.config["username"] == "testuser"
      assert updated_definition.config["password"] == "testpass"
    end
  end

  describe "empty states" do
    setup :register_and_log_in_admin
    setup :enable_cardigann_feature_flag

    test "shows message when no indexers exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/config/indexers/library")
      assert html =~ "No Cardigann definitions available"
      assert html =~ "Sync Definitions"
    end

    test "shows message when filters return no results", %{conn: conn} do
      cardigann_definition_fixture(%{type: "public"})

      {:ok, view, _html} = live(conn, ~p"/admin/config/indexers/library")

      html =
        view
        |> element("select[name='type']")
        |> render_change(%{"type" => "private"})

      assert html =~ "No indexers match your filters"
    end
  end

  describe "navigation" do
    setup :register_and_log_in_admin

    setup do
      # Start the Indexers.Health GenServer to initialize ETS tables
      start_supervised!(Mydia.Indexers.Health)
      :ok
    end

    test "admin config page shows Cardigann library link when enabled", %{conn: conn} do
      set_cardigann_feature_flag(true)

      {:ok, _view, html} = live(conn, ~p"/admin/config?tab=indexers")
      # The link text is "Cardigann" (without "Library" suffix)
      assert html =~ "Cardigann"
      assert html =~ ~p"/admin/config/indexers/library"
    end

    test "admin config page hides Cardigann library link when disabled", %{conn: conn} do
      set_cardigann_feature_flag(false)

      {:ok, _view, html} = live(conn, ~p"/admin/config?tab=indexers")
      refute html =~ "Cardigann Library"
    end
  end

  # Helper functions

  defp register_and_log_in_admin(%{conn: conn}) do
    admin = admin_user_fixture()
    %{conn: log_in_user(conn, admin), admin: admin}
  end

  defp enable_cardigann_feature_flag(_context) do
    set_cardigann_feature_flag(true)
    :ok
  end

  defp set_cardigann_feature_flag(enabled) do
    current_features = Application.get_env(:mydia, :features, [])
    updated_features = Keyword.put(current_features, :cardigann_enabled, enabled)
    Application.put_env(:mydia, :features, updated_features)

    on_exit(fn ->
      Application.put_env(:mydia, :features, current_features)
    end)
  end
end
