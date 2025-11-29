defmodule Mydia.Music.MusicFile do
  @moduledoc """
  Schema for music files (audio files on disk).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "music_files" do
    field :path, :string
    field :relative_path, :string
    field :size, :integer
    field :bitrate, :integer
    field :sample_rate, :integer
    field :codec, :string
    field :channels, :integer
    field :duration, :integer

    belongs_to :track, Mydia.Music.Track
    belongs_to :library_path, Mydia.Settings.LibraryPath

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a music file.
  """
  def changeset(music_file, attrs) do
    music_file
    |> cast(attrs, [
      :path,
      :relative_path,
      :size,
      :bitrate,
      :sample_rate,
      :codec,
      :channels,
      :duration,
      :track_id,
      :library_path_id
    ])
    |> validate_required([:path])
    |> unique_constraint(:path)
    |> foreign_key_constraint(:track_id)
    |> foreign_key_constraint(:library_path_id)
  end
end
