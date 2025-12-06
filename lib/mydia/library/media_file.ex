defmodule Mydia.Library.MediaFile do
  @moduledoc """
  Schema for media files (multiple versions support).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "media_files" do
    field :path, :string
    field :size, :integer
    field :resolution, :string
    field :codec, :string
    field :hdr_format, :string
    field :audio_codec, :string
    field :bitrate, :integer
    field :verified_at, :utc_datetime
    field :metadata, Mydia.Settings.JsonMapType

    # Generated media content references (MD5 checksums as storage keys)
    field :cover_blob, :string
    field :sprite_blob, :string
    field :vtt_blob, :string
    field :preview_blob, :string
    field :phash, :string
    field :generated_at, :utc_datetime

    # Relative path storage (Phase 1)
    field :relative_path, :string
    belongs_to :library_path, Mydia.Settings.LibraryPath

    belongs_to :media_item, Mydia.Media.MediaItem
    belongs_to :episode, Mydia.Media.Episode
    belongs_to :quality_profile, Mydia.Settings.QualityProfile

    timestamps(type: :utc_datetime)
  end

  @doc """
  Resolves the absolute file path from relative_path and library_path.

  The library_path association must be preloaded.

  ## Examples

      iex> file = %MediaFile{relative_path: "Movie.mkv", library_path: %LibraryPath{path: "/movies"}}
      iex> MediaFile.absolute_path(file)
      "/movies/Movie.mkv"

      iex> file = %MediaFile{relative_path: "Movie.mkv", library_path: nil}
      iex> MediaFile.absolute_path(file)
      nil
  """
  def absolute_path(%__MODULE__{relative_path: relative_path, library_path: library_path})
      when not is_nil(relative_path) and not is_nil(library_path) do
    Path.join(library_path.path, relative_path)
  end

  def absolute_path(%__MODULE__{}), do: nil

  @doc """
  Changeset for creating or updating a media file.
  """
  def changeset(media_file, attrs) do
    media_file
    |> cast(attrs, [
      :media_item_id,
      :episode_id,
      :quality_profile_id,
      :path,
      :relative_path,
      :library_path_id,
      :size,
      :resolution,
      :codec,
      :hdr_format,
      :audio_codec,
      :bitrate,
      :verified_at,
      :metadata,
      :cover_blob,
      :sprite_blob,
      :vtt_blob,
      :preview_blob,
      :phash,
      :generated_at
    ])
    |> validate_required([:relative_path, :library_path_id])
    |> validate_one_parent()
    |> validate_library_type_compatibility()
    |> validate_number(:size, greater_than: 0)
    |> validate_number(:bitrate, greater_than: 0)
    |> check_constraint(:media_item_id,
      name: :media_files_parent_check,
      message: "cannot set both media_item_id and episode_id"
    )
    |> foreign_key_constraint(:media_item_id)
    |> foreign_key_constraint(:episode_id)
    |> foreign_key_constraint(:quality_profile_id)
    |> foreign_key_constraint(:library_path_id)
  end

  @doc """
  Changeset for creating a media file during library scanning.
  Parent association (media_item_id or episode_id) is optional during initial creation
  and will be set later during metadata enrichment.
  """
  def scan_changeset(media_file, attrs) do
    media_file
    |> cast(attrs, [
      :media_item_id,
      :episode_id,
      :quality_profile_id,
      :relative_path,
      :library_path_id,
      :size,
      :resolution,
      :codec,
      :hdr_format,
      :audio_codec,
      :bitrate,
      :verified_at,
      :metadata,
      :cover_blob,
      :sprite_blob,
      :vtt_blob,
      :preview_blob,
      :phash,
      :generated_at
    ])
    |> validate_required([:relative_path, :library_path_id])
    |> validate_parent_exclusivity()
    |> validate_library_type_compatibility()
    |> validate_number(:size, greater_than: 0)
    |> validate_number(:bitrate, greater_than: 0)
    |> check_constraint(:media_item_id,
      name: :media_files_parent_check,
      message: "cannot set both media_item_id and episode_id"
    )
    |> foreign_key_constraint(:media_item_id)
    |> foreign_key_constraint(:episode_id)
    |> foreign_key_constraint(:quality_profile_id)
    |> foreign_key_constraint(:library_path_id)
  end

  # Ensure either media_item_id or episode_id is set, but not both
  # Exception: specialized library types (music, books, adult) allow both to be nil
  defp validate_one_parent(changeset) do
    media_item_id = get_field(changeset, :media_item_id)
    episode_id = get_field(changeset, :episode_id)
    library_path_id = get_field(changeset, :library_path_id)

    cond do
      # Both are nil - check if this is a specialized library type
      is_nil(media_item_id) and is_nil(episode_id) ->
        if specialized_library?(library_path_id) do
          # Specialized libraries (music, books, adult) don't require media_item/episode
          changeset
        else
          add_error(changeset, :media_item_id, "either media_item_id or episode_id must be set")
        end

      not is_nil(media_item_id) and not is_nil(episode_id) ->
        add_error(changeset, :media_item_id, "cannot set both media_item_id and episode_id")

      true ->
        changeset
    end
  end

  # Checks if the library path is a specialized type (music, books, adult)
  defp specialized_library?(nil), do: false

  defp specialized_library?(library_path_id) do
    case Mydia.Repo.get(Mydia.Settings.LibraryPath, library_path_id) do
      nil -> false
      library_path -> library_path.type in [:music, :books, :adult]
    end
  end

  # Ensure both media_item_id and episode_id are not set at the same time
  # (allows both to be nil for orphaned files during scanning)
  defp validate_parent_exclusivity(changeset) do
    media_item_id = get_field(changeset, :media_item_id)
    episode_id = get_field(changeset, :episode_id)

    if not is_nil(media_item_id) and not is_nil(episode_id) do
      add_error(changeset, :media_item_id, "cannot set both media_item_id and episode_id")
    else
      changeset
    end
  end

  # Validates that the media type is compatible with the library path type
  defp validate_library_type_compatibility(changeset) do
    media_item_id = get_field(changeset, :media_item_id)
    episode_id = get_field(changeset, :episode_id)
    library_path_id = get_field(changeset, :library_path_id)

    # Skip validation if library_path_id is missing (will be caught by validate_required)
    if is_nil(library_path_id) do
      changeset
    else
      # Check if this is a specialized library type
      if specialized_library?(library_path_id) do
        # For specialized libraries, we don't need media_item/episode validation
        # Files can exist without associations in music, books, adult libraries
        changeset
      else
        # For standard video libraries, validate media type compatibility
        # Only validate if parent association is set (orphaned files are allowed)
        if is_nil(media_item_id) and is_nil(episode_id) do
          changeset
        else
          validate_media_type_against_library_path_id(
            changeset,
            library_path_id,
            media_item_id,
            episode_id
          )
        end
      end
    end
  end

  defp validate_media_type_against_library_path_id(
         changeset,
         library_path_id,
         media_item_id,
         episode_id
       ) do
    case Mydia.Repo.get(Mydia.Settings.LibraryPath, library_path_id) do
      nil ->
        # Library path not found, let foreign key constraint handle it
        changeset

      library_path ->
        cond do
          # If library is :mixed, allow both types
          library_path.type == :mixed ->
            changeset

          # Movie in :series library
          not is_nil(media_item_id) and library_path.type == :series ->
            media_type = get_media_type_for_item(media_item_id)

            if media_type == "movie" do
              add_error(
                changeset,
                :media_item_id,
                "cannot add movies to a library path configured for TV series only (path: #{library_path.path})"
              )
            else
              changeset
            end

          # TV show in :movies library
          not is_nil(episode_id) and library_path.type == :movies ->
            add_error(
              changeset,
              :episode_id,
              "cannot add TV episodes to a library path configured for movies only (path: #{library_path.path})"
            )

          # All other cases are valid
          true ->
            changeset
        end
    end
  end

  # Gets the media type (movie or tv_show) for a media item by ID
  defp get_media_type_for_item(media_item_id) do
    case Mydia.Repo.get(Mydia.Media.MediaItem, media_item_id) do
      nil -> nil
      media_item -> media_item.type
    end
  end
end
