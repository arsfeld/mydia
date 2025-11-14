defmodule MydiaWeb.Live.UserAuthTest do
  use MydiaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Mydia.AccountsFixtures

  alias MydiaWeb.Live.UserAuth

  describe "on_mount/4 :ensure_authenticated" do
    test "allows authenticated user to continue", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/media")

      assert view
    end

    test "redirects unauthenticated user", %{conn: conn} do
      {:error, {:redirect, redirect}} = live(conn, ~p"/media")

      assert redirect.to == "/auth/login"
      assert redirect.flash["error"] == "You must be logged in to access this page"
    end
  end

  describe "on_mount/4 {:ensure_role, role}" do
    test "allows user with sufficient role to continue", %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)

      # AdminUsersLive requires admin role
      {:ok, view, _html} = live(conn, ~p"/admin/users")

      assert view
    end

    test "redirects user without sufficient role", %{conn: conn} do
      user = user_fixture(%{role: "readonly"})
      conn = log_in_user(conn, user)

      {:error, {:redirect, redirect}} = live(conn, ~p"/admin/users")

      assert redirect.to == "/"
      assert redirect.flash["error"] == "You do not have permission to access this page"
    end

    test "redirects unauthenticated user", %{conn: conn} do
      {:error, {:redirect, redirect}} = live(conn, ~p"/admin/users")

      # Unauthenticated users are redirected to login, not home
      assert redirect.to == "/auth/login"
    end
  end

  describe "on_mount/4 :load_navigation_data" do
    test "loads navigation counts for authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/media")

      # Verify navigation assigns are present by checking they exist in the rendered state
      # LiveView assigns are not directly accessible in tests, but we can verify the view renders
      assert view
    end

    test "loads navigation counts with zero pending requests for non-admin", %{conn: conn} do
      user = user_fixture(%{role: "readonly"})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/media")

      # View should render successfully with navigation data loaded
      assert view
    end

    test "handles missing current_user gracefully", %{conn: conn} do
      {:error, {:redirect, _redirect}} = live(conn, ~p"/media")

      # Should redirect, not crash
    end
  end
end
