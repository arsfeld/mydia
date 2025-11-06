defmodule MydiaWeb.AdminStatusLiveTest do
  use MydiaWeb.ConnCase

  import Phoenix.LiveViewTest
  import MydiaWeb.AuthHelpers
  import Mydia.AccountsFixtures

  describe "Index - Authentication" do
    test "requires authentication", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/status")
      # Should redirect to login
      assert path =~ "/auth"
    end

    test "requires admin role", %{conn: conn} do
      # Create and log in a regular user (non-admin)
      user = user_fixture(%{role: "user"})
      conn = log_in_user(conn, user)

      # Regular user should not be able to access admin status
      assert_error_sent(403, fn ->
        get(conn, ~p"/admin/status")
      end)
    end

    test "allows admin access", %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/admin/status")
      assert html =~ "System Status"
    end
  end

  describe "Index - Content" do
    setup %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/admin/status")
      %{conn: conn, view: view}
    end

    test "displays system information", %{view: view} do
      assert has_element?(view, "h2", "System Information")
      assert has_element?(view, ".stat-title", "Elixir Version")
      assert has_element?(view, ".stat-title", "OTP Version")
      assert has_element?(view, ".stat-title", "Uptime")
    end

    test "displays database information", %{view: view} do
      assert has_element?(view, "h2", "Database")
    end
  end
end
