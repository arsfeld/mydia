defmodule Mydia.Library.ImportSession do
  @moduledoc """
  Schema for storing import workflow state across page refreshes.

  Import sessions allow users to safely refresh the page during long import
  workflows without losing their progress. Sessions store the current step,
  scanned files, matched metadata, and user selections.

  Sessions automatically expire after 24 hours to prevent database bloat.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mydia.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_steps ~w(select_path review importing complete)a
  @valid_statuses ~w(active completed expired abandoned)a

  schema "import_sessions" do
    field :step, Ecto.Enum, values: @valid_steps, default: :select_path
    field :status, Ecto.Enum, values: @valid_statuses, default: :active
    field :scan_path, :string
    field :session_data, Mydia.Settings.JsonMapType
    field :scan_stats, Mydia.Settings.JsonMapType
    field :import_progress, Mydia.Settings.JsonMapType
    field :import_results, Mydia.Settings.JsonMapType
    field :completed_at, :utc_datetime
    field :expires_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a new import session for a user.
  Optionally accepts an :id to create a session with a specific UUID.
  """
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :id,
      :user_id,
      :step,
      :status,
      :scan_path,
      :session_data,
      :scan_stats,
      :import_progress,
      :import_results
    ])
    |> validate_required([:user_id])
    |> put_default_expiry()
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Updates an existing import session.
  """
  def changeset(import_session, attrs) do
    import_session
    |> cast(attrs, [
      :step,
      :status,
      :scan_path,
      :session_data,
      :scan_stats,
      :import_progress,
      :import_results,
      :completed_at,
      :expires_at
    ])
    |> validate_inclusion(:step, @valid_steps)
    |> validate_inclusion(:status, @valid_statuses)
    |> maybe_set_completed_at()
  end

  @doc """
  Marks a session as completed.
  """
  def complete_changeset(import_session) do
    import_session
    |> change(%{
      status: :completed,
      step: :complete,
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc """
  Marks a session as abandoned (user started a new one).
  """
  def abandon_changeset(import_session) do
    import_session
    |> change(%{status: :abandoned})
  end

  # Private functions

  defp put_default_expiry(changeset) do
    # Sessions expire after 24 hours
    expires_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(24, :hour)
    put_change(changeset, :expires_at, expires_at)
  end

  defp maybe_set_completed_at(changeset) do
    case get_change(changeset, :status) do
      :completed ->
        if get_field(changeset, :completed_at) == nil do
          put_change(changeset, :completed_at, DateTime.utc_now() |> DateTime.truncate(:second))
        else
          changeset
        end

      _ ->
        changeset
    end
  end
end
