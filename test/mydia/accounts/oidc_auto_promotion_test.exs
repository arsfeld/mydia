defmodule Mydia.Accounts.OidcAutoPromotionTest do
  use Mydia.DataCase, async: true

  alias Mydia.Accounts

  describe "admin_exists?/0" do
    test "returns false when no users exist" do
      refute Accounts.admin_exists?()
    end

    test "returns false when only non-admin users exist" do
      Accounts.create_user(%{
        username: "user1",
        email: "user1@example.com",
        password: "password123",
        role: "user"
      })

      Accounts.create_user(%{
        username: "guest1",
        email: "guest1@example.com",
        password: "password123",
        role: "guest"
      })

      refute Accounts.admin_exists?()
    end

    test "returns true when at least one admin user exists" do
      Accounts.create_user(%{
        username: "admin",
        email: "admin@example.com",
        password: "password123",
        role: "admin"
      })

      assert Accounts.admin_exists?()
    end

    test "returns true when admin exists among other users" do
      Accounts.create_user(%{
        username: "user1",
        email: "user1@example.com",
        password: "password123",
        role: "user"
      })

      Accounts.create_user(%{
        username: "admin",
        email: "admin@example.com",
        password: "password123",
        role: "admin"
      })

      assert Accounts.admin_exists?()
    end
  end

  describe "upsert_user_from_oidc/3 - first user auto-promotion" do
    @tag :skip
    test "promotes first OIDC user to admin when no admin exists" do
      {:ok, user} =
        Accounts.upsert_user_from_oidc("oidc-sub-123", "google", %{
          email: "first@example.com",
          display_name: "First User",
          role: "user"
        })

      assert user.role == "admin"
      assert user.email == "first@example.com"
      assert user.oidc_sub == "oidc-sub-123"
      assert user.oidc_issuer == "google"
    end

    test "does not promote when admin already exists" do
      # Create an admin user first
      Accounts.create_user(%{
        username: "existing_admin",
        email: "admin@example.com",
        password: "password123",
        role: "admin"
      })

      # New OIDC user should get role from claims, not auto-promoted
      {:ok, user} =
        Accounts.upsert_user_from_oidc("oidc-sub-456", "google", %{
          email: "second@example.com",
          display_name: "Second User",
          role: "user"
        })

      assert user.role == "user"
      refute user.role == "admin"
    end

    @tag :skip
    test "does not promote when OIDC admin already exists" do
      # Create first OIDC user (will be promoted to admin)
      {:ok, _first_user} =
        Accounts.upsert_user_from_oidc("oidc-sub-first", "google", %{
          email: "first@example.com",
          display_name: "First User",
          role: "user"
        })

      # Second OIDC user should get their role from claims
      {:ok, second_user} =
        Accounts.upsert_user_from_oidc("oidc-sub-second", "google", %{
          email: "second@example.com",
          display_name: "Second User",
          role: "readonly"
        })

      assert second_user.role == "readonly"
      refute second_user.role == "admin"
    end

    @tag :skip
    test "does not promote existing OIDC user on subsequent logins" do
      # First login - user gets promoted to admin
      {:ok, user} =
        Accounts.upsert_user_from_oidc("oidc-sub-999", "google", %{
          email: "user@example.com",
          display_name: "User",
          role: "user"
        })

      assert user.role == "admin"

      # Subsequent login with different role - should update from OIDC claims, not auto-promote
      {:ok, returned_user} =
        Accounts.upsert_user_from_oidc("oidc-sub-999", "google", %{
          email: "user@example.com",
          display_name: "User Updated",
          role: "guest"
        })

      # Role should be updated from OIDC claims (existing users get OIDC role)
      assert returned_user.role == "guest"
      assert returned_user.id == user.id
    end

    test "respects OIDC admin role even when auto-promotion would apply" do
      {:ok, user} =
        Accounts.upsert_user_from_oidc("oidc-sub-admin", "google", %{
          email: "oidc_admin@example.com",
          display_name: "OIDC Admin",
          role: "admin"
        })

      # Even though OIDC claims say "admin", the user would be promoted anyway
      # since no admin existed. The important thing is they end up as admin.
      assert user.role == "admin"
    end

    @tag :skip
    test "updates display_name and avatar on existing user login" do
      # First login
      {:ok, user} =
        Accounts.upsert_user_from_oidc("oidc-sub-update", "google", %{
          email: "user@example.com",
          display_name: "Original Name",
          avatar_url: "https://example.com/avatar1.jpg",
          role: "user"
        })

      original_id = user.id

      # Second login with updated info
      {:ok, updated_user} =
        Accounts.upsert_user_from_oidc("oidc-sub-update", "google", %{
          email: "user@example.com",
          display_name: "Updated Name",
          avatar_url: "https://example.com/avatar2.jpg",
          role: "readonly"
        })

      assert updated_user.id == original_id
      assert updated_user.display_name == "Updated Name"
      assert updated_user.avatar_url == "https://example.com/avatar2.jpg"
      assert updated_user.role == "readonly"
    end
  end
end
