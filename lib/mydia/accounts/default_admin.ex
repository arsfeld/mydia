defmodule Mydia.Accounts.DefaultAdmin do
  @moduledoc """
  Handles automatic creation of a default admin user on application startup
  if no admin user exists in the system.
  """

  require Logger
  import Ecto.Query
  alias Mydia.Accounts
  alias Mydia.Accounts.User
  alias Mydia.Repo

  @default_username "admin"
  @default_email "admin@mydia.local"
  @password_length 24

  @doc """
  Ensures a default admin user exists in the system.

  This function is idempotent and safe to call on every application startup.
  It will:
  - Check if any admin user exists
  - If not, create one with either:
    - A pre-hashed password from ADMIN_PASSWORD_HASH env var, or
    - A randomly generated secure password (logged to console)

  Returns:
  - `:ok` if an admin already exists
  - `{:ok, username, password}` if a new admin was created with a random password
  - `{:ok, username}` if a new admin was created with a pre-hashed password
  - `{:error, reason}` if admin creation failed
  """
  def ensure_admin_exists do
    if admin_exists?() do
      :ok
    else
      create_default_admin()
    end
  end

  defp admin_exists? do
    Repo.exists?(from u in User, where: u.role == "admin")
  end

  defp create_default_admin do
    username = get_admin_username()
    email = get_admin_email()

    case System.get_env("ADMIN_PASSWORD_HASH") do
      nil ->
        create_admin_with_random_password(username, email)

      password_hash when is_binary(password_hash) ->
        create_admin_with_hash(username, email, password_hash)
    end
  end

  defp create_admin_with_random_password(username, email) do
    password = generate_secure_password()

    attrs = %{
      username: username,
      email: email,
      password: password,
      role: "admin",
      display_name: "Administrator"
    }

    case Accounts.create_user(attrs) do
      {:ok, user} ->
        log_admin_created_with_password(user.username, password)
        {:ok, user.username, password}

      {:error, changeset} ->
        Logger.error("Failed to create default admin user: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  defp create_admin_with_hash(username, email, password_hash) do
    # Create a changeset that directly sets the password_hash without hashing
    changeset =
      %User{}
      |> Ecto.Changeset.cast(%{username: username, email: email, role: "admin"}, [
        :username,
        :email,
        :role
      ])
      |> Ecto.Changeset.validate_required([:username, :email, :role])
      |> Ecto.Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
        message: "must be a valid email"
      )
      |> Ecto.Changeset.validate_length(:username, min: 3, max: 50)
      |> Ecto.Changeset.validate_inclusion(:role, User.valid_roles())
      |> Ecto.Changeset.put_change(:password_hash, password_hash)
      |> Ecto.Changeset.put_change(:display_name, "Administrator")
      |> Ecto.Changeset.unique_constraint(:username)
      |> Ecto.Changeset.unique_constraint(:email)

    case Repo.insert(changeset) do
      {:ok, user} ->
        Logger.info("Default admin user '#{user.username}' created with provided password hash")
        {:ok, user.username}

      {:error, changeset} ->
        Logger.error("Failed to create default admin user: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  defp generate_secure_password do
    # Generate a cryptographically secure random password
    :crypto.strong_rand_bytes(@password_length)
    |> Base.url_encode64()
    |> binary_part(0, @password_length)
  end

  defp get_admin_username do
    System.get_env("ADMIN_USERNAME", @default_username)
  end

  defp get_admin_email do
    System.get_env("ADMIN_EMAIL", @default_email)
  end

  defp log_admin_created_with_password(username, password) do
    Logger.warning("""

    ================================================================================
    DEFAULT ADMIN USER CREATED
    ================================================================================

    A default admin user has been created for initial access to Mydia.

    Username: #{username}
    Password: #{password}

    IMPORTANT:
    - Please save this password securely
    - Change this password after your first login
    - This message will only be shown once

    ================================================================================
    """)
  end
end
