defmodule MydiaWeb.Live.AuthorizationTest do
  use MydiaWeb.ConnCase, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Mydia.AccountsFixtures

  alias MydiaWeb.Live.Authorization

  # Helper to build a mock socket with flash support
  defp build_socket(_conn, assigns) do
    socket = %Phoenix.LiveView.Socket{
      endpoint: MydiaWeb.Endpoint,
      assigns: Map.merge(%{__changed__: %{}, flash: %{}}, assigns)
    }

    {:ok, socket}
  end

  describe "authorize_create_media/1" do
    test "returns :ok for admin user", %{conn: conn} do
      admin = admin_user_fixture()
      {:ok, socket} = build_socket(conn, %{current_user: admin})

      assert :ok == Authorization.authorize_create_media(socket)
    end

    test "returns :ok for user role", %{conn: conn} do
      user = user_fixture(%{role: "user"})
      {:ok, socket} = build_socket(conn, %{current_user: user})

      assert :ok == Authorization.authorize_create_media(socket)
    end

    test "returns {:unauthorized, socket} for readonly user", %{conn: conn} do
      readonly_user = user_fixture(%{role: "readonly"})
      {:ok, socket} = build_socket(conn, %{current_user: readonly_user})

      assert {:unauthorized, _updated_socket} = Authorization.authorize_create_media(socket)
    end

    test "raises when current_user is missing", %{conn: conn} do
      {:ok, socket} = build_socket(conn, %{})

      assert_raise RuntimeError,
                   "current_user is required in socket assigns for authorization",
                   fn ->
                     Authorization.authorize_create_media(socket)
                   end
    end

    test "raises when current_user is nil", %{conn: conn} do
      {:ok, socket} = build_socket(conn, %{current_user: nil})

      assert_raise RuntimeError,
                   "current_user is required in socket assigns for authorization",
                   fn ->
                     Authorization.authorize_create_media(socket)
                   end
    end
  end

  describe "authorize_update_media/1" do
    test "returns :ok for authorized user", %{conn: conn} do
      user = user_fixture(%{role: "user"})
      {:ok, socket} = build_socket(conn, %{current_user: user})

      assert :ok == Authorization.authorize_update_media(socket)
    end

    test "returns {:unauthorized, socket} for unauthorized user", %{conn: conn} do
      guest = user_fixture(%{role: "guest"})
      {:ok, socket} = build_socket(conn, %{current_user: guest})

      assert {:unauthorized, _socket} = Authorization.authorize_update_media(socket)
    end

    test "raises when current_user is missing", %{conn: conn} do
      {:ok, socket} = build_socket(conn, %{})

      assert_raise RuntimeError,
                   "current_user is required in socket assigns for authorization",
                   fn ->
                     Authorization.authorize_update_media(socket)
                   end
    end
  end

  describe "authorize_delete_media/1" do
    test "returns :ok for authorized user", %{conn: conn} do
      admin = admin_user_fixture()
      {:ok, socket} = build_socket(conn, %{current_user: admin})

      assert :ok == Authorization.authorize_delete_media(socket)
    end

    test "returns {:unauthorized, socket} for unauthorized user", %{conn: conn} do
      readonly_user = user_fixture(%{role: "readonly"})
      {:ok, socket} = build_socket(conn, %{current_user: readonly_user})

      assert {:unauthorized, _socket} = Authorization.authorize_delete_media(socket)
    end

    test "raises when current_user is missing", %{conn: conn} do
      {:ok, socket} = build_socket(conn, %{})

      assert_raise RuntimeError,
                   "current_user is required in socket assigns for authorization",
                   fn ->
                     Authorization.authorize_delete_media(socket)
                   end
    end
  end

  describe "authorize_manage_downloads/1" do
    test "returns :ok for authorized user", %{conn: conn} do
      user = user_fixture(%{role: "user"})
      {:ok, socket} = build_socket(conn, %{current_user: user})

      assert :ok == Authorization.authorize_manage_downloads(socket)
    end

    test "returns {:unauthorized, socket} for unauthorized user", %{conn: conn} do
      readonly_user = user_fixture(%{role: "readonly"})
      {:ok, socket} = build_socket(conn, %{current_user: readonly_user})

      assert {:unauthorized, _socket} = Authorization.authorize_manage_downloads(socket)
    end

    test "raises when current_user is missing", %{conn: conn} do
      {:ok, socket} = build_socket(conn, %{})

      assert_raise RuntimeError,
                   "current_user is required in socket assigns for authorization",
                   fn ->
                     Authorization.authorize_manage_downloads(socket)
                   end
    end
  end

  describe "authorize_import_media/1" do
    test "returns :ok for authorized user", %{conn: conn} do
      user = user_fixture(%{role: "user"})
      {:ok, socket} = build_socket(conn, %{current_user: user})

      assert :ok == Authorization.authorize_import_media(socket)
    end

    test "returns {:unauthorized, socket} for unauthorized user", %{conn: conn} do
      guest = user_fixture(%{role: "guest"})
      {:ok, socket} = build_socket(conn, %{current_user: guest})

      assert {:unauthorized, _socket} = Authorization.authorize_import_media(socket)
    end

    test "raises when current_user is missing", %{conn: conn} do
      {:ok, socket} = build_socket(conn, %{})

      assert_raise RuntimeError,
                   "current_user is required in socket assigns for authorization",
                   fn ->
                     Authorization.authorize_import_media(socket)
                   end
    end
  end

  describe "authorize/3" do
    test "returns :ok when permission function returns true", %{conn: conn} do
      user = user_fixture(%{role: "admin"})
      {:ok, socket} = build_socket(conn, %{current_user: user})
      permission_fn = fn _user -> true end

      assert :ok == Authorization.authorize(socket, permission_fn, "Custom error")
    end

    test "returns {:unauthorized, socket} when permission function returns false", %{conn: conn} do
      user = user_fixture(%{role: "guest"})
      {:ok, socket} = build_socket(conn, %{current_user: user})
      permission_fn = fn _user -> false end

      assert {:unauthorized, _updated_socket} =
               Authorization.authorize(socket, permission_fn, "Custom error")
    end

    test "raises when current_user is missing", %{conn: conn} do
      {:ok, socket} = build_socket(conn, %{})
      permission_fn = fn _user -> true end

      assert_raise RuntimeError,
                   "current_user is required in socket assigns for authorization",
                   fn ->
                     Authorization.authorize(socket, permission_fn, "Custom error")
                   end
    end
  end
end
