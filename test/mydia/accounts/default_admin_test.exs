defmodule Mydia.Accounts.DefaultAdminTest do
  use Mydia.DataCase, async: false

  import Ecto.Query
  import Mydia.AccountsFixtures

  alias Mydia.Accounts
  alias Mydia.Accounts.DefaultAdmin
  alias Mydia.Repo

  describe "ensure_admin_exists/0" do
    test "returns :ok when an admin user already exists" do
      # Create an admin user
      user_fixture(%{role: "admin"})

      # Should not create another admin
      assert :ok = DefaultAdmin.ensure_admin_exists()

      # Verify only one admin exists
      admin_count =
        Repo.aggregate(from(u in Mydia.Accounts.User, where: u.role == "admin"), :count)

      assert admin_count == 1
    end

    test "creates admin user with random password when no admin exists and no env var" do
      # Ensure no admin users exist
      Repo.delete_all(from(u in Mydia.Accounts.User, where: u.role == "admin"))

      # Should create a new admin with random password
      assert {:ok, username, password} = DefaultAdmin.ensure_admin_exists()

      # Verify the admin was created
      admin = Accounts.get_user_by_username(username)
      assert admin
      assert admin.role == "admin"
      assert admin.username == "admin"
      assert admin.email == "admin@mydia.local"

      # Verify the password works
      assert Accounts.verify_password(admin, password)
    end

    test "creates admin user with pre-hashed password from env var" do
      # Ensure no admin users exist
      Repo.delete_all(from(u in Mydia.Accounts.User, where: u.role == "admin"))

      # Generate a password hash for testing
      password = "test_password_123"
      password_hash = Bcrypt.hash_pwd_salt(password)

      # Set the environment variable
      System.put_env("ADMIN_PASSWORD_HASH", password_hash)

      try do
        # Should create a new admin with the provided hash
        assert {:ok, username} = DefaultAdmin.ensure_admin_exists()

        # Verify the admin was created
        admin = Accounts.get_user_by_username(username)
        assert admin
        assert admin.role == "admin"
        assert admin.password_hash == password_hash

        # Verify the password works with the original password
        assert Accounts.verify_password(admin, password)
      after
        # Clean up the environment variable
        System.delete_env("ADMIN_PASSWORD_HASH")
      end
    end

    test "respects custom ADMIN_USERNAME and ADMIN_EMAIL env vars" do
      # Ensure no admin users exist
      Repo.delete_all(from(u in Mydia.Accounts.User, where: u.role == "admin"))

      # Set custom username and email
      System.put_env("ADMIN_USERNAME", "superadmin")
      System.put_env("ADMIN_EMAIL", "superadmin@example.com")

      try do
        # Should create a new admin with custom username and email
        assert {:ok, username, _password} = DefaultAdmin.ensure_admin_exists()

        # Verify the custom values were used
        assert username == "superadmin"

        admin = Accounts.get_user_by_username(username)
        assert admin.email == "superadmin@example.com"
      after
        # Clean up the environment variables
        System.delete_env("ADMIN_USERNAME")
        System.delete_env("ADMIN_EMAIL")
      end
    end

    test "is idempotent - does not create duplicate admins on repeated calls" do
      # Ensure no admin users exist
      Repo.delete_all(from(u in Mydia.Accounts.User, where: u.role == "admin"))

      # First call should create an admin
      assert {:ok, _username, _password} = DefaultAdmin.ensure_admin_exists()

      # Second call should return :ok without creating another admin
      assert :ok = DefaultAdmin.ensure_admin_exists()

      # Verify only one admin exists
      admin_count =
        Repo.aggregate(from(u in Mydia.Accounts.User, where: u.role == "admin"), :count)

      assert admin_count == 1
    end
  end
end
