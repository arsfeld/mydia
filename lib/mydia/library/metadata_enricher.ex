defmodule Mydia.Library.MetadataEnricher do
  @moduledoc """
  Enriches media items with full metadata from providers.

  This module takes a matched media item (with provider ID) and:
  - Fetches detailed metadata (description, cast, crew, ratings, genres, etc.)
  - Downloads and stores poster/backdrop images
  - For TV shows, fetches and creates episode records
  - Stores everything in the database
  """

  require Logger
  alias Mydia.{Media, Metadata, Settings}

  @doc """
  Enriches a media item with full metadata from the provider.

  Takes a match result from MetadataMatcher and fetches/stores all metadata.

  ## Parameters
    - `match_result` - Result from MetadataMatcher.match_file/2
    - `opts` - Options
      - `:config` - Provider configuration (default: Metadata.default_relay_config())
      - `:fetch_episodes` - For TV shows, whether to fetch episode data (default: true)
      - `:media_file_id` - Optional media file ID to associate

  ## Examples

      iex> match_result = %{provider_id: "603", provider_type: :tmdb, ...}
      iex> MetadataEnricher.enrich(match_result)
      {:ok, %MediaItem{title: "The Matrix", ...}}
  """
  def enrich(%{provider_id: provider_id, provider_type: provider_type} = match_result, opts \\ []) do
    config = Keyword.get(opts, :config, Metadata.default_relay_config())
    media_file_id = Keyword.get(opts, :media_file_id)

    media_type = determine_media_type(match_result)

    Logger.info("Enriching media with full metadata",
      provider_id: provider_id,
      provider_type: provider_type,
      media_type: media_type,
      title: match_result.title,
      media_file_id: media_file_id,
      has_parsed_info: Map.has_key?(match_result, :parsed_info),
      parsed_info: Map.get(match_result, :parsed_info)
    )

    # Validate library type compatibility if we have a media file
    with :ok <- validate_library_type_compatibility(media_type, media_file_id) do
      # Check if media item already exists
      case get_or_create_media_item(provider_id, media_type, match_result, config) do
        {:ok, media_item} ->
          # Associate media file with media_item for movies only
          # For TV shows, files are associated with episodes instead
          if media_file_id && media_type == :movie do
            associate_media_file(media_item, media_file_id)
          end

          # For TV shows, fetch and create episodes
          if media_type == :tv_show and Keyword.get(opts, :fetch_episodes, true) do
            # Add media_file_id to match_result so it can be used for episode file association
            match_result_with_file_id =
              if media_file_id do
                Logger.info("""
                Adding media_file_id to match_result for episode association:
                  media_file_id: #{inspect(media_file_id)}
                  season: #{inspect(match_result.parsed_info.season)}
                  episodes: #{inspect(match_result.parsed_info.episodes)}
                  parsed_info type: #{inspect(match_result.parsed_info.type)}
                """)

                Map.put(match_result, :media_file_id, media_file_id)
              else
                Logger.warning("No media_file_id provided for TV show import")
                match_result
              end

            enrich_episodes(media_item, provider_id, config, match_result_with_file_id)
          end

          {:ok, media_item}

        {:error, reason} = error ->
          Logger.error("Failed to enrich media",
            provider_id: provider_id,
            reason: reason
          )

          error
      end
    else
      {:error, reason} = error ->
        Logger.error("Library type validation failed",
          provider_id: provider_id,
          media_type: media_type,
          media_file_id: media_file_id,
          reason: reason
        )

        error
    end
  end

  ## Private Functions

  defp determine_media_type(%{parsed_info: %{type: :movie}}), do: :movie
  defp determine_media_type(%{parsed_info: %{type: :tv_show}}), do: :tv_show

  defp determine_media_type(%{metadata: %{media_type: media_type}})
       when media_type in [:movie, :tv_show],
       do: media_type

  defp determine_media_type(_), do: :movie

  defp get_or_create_media_item(provider_id, media_type, match_result, config) do
    tmdb_id = String.to_integer(provider_id)

    # Check if media item already exists
    case Media.get_media_item_by_tmdb(tmdb_id) do
      nil ->
        # Fetch full metadata and create new item
        create_new_media_item(provider_id, media_type, match_result, config)

      existing_item ->
        # Update existing item with latest metadata
        update_existing_media_item(existing_item, provider_id, media_type, config)
    end
  end

  defp create_new_media_item(provider_id, media_type, match_result, config) do
    Logger.debug("Creating new media item", provider_id: provider_id, type: media_type)

    case fetch_full_metadata(provider_id, media_type, config) do
      {:ok, full_metadata} ->
        attrs = build_media_item_attrs(full_metadata, media_type, match_result)

        case Media.create_media_item(attrs) do
          {:ok, media_item} ->
            # Episodes will be fetched by enrich_episodes if needed
            {:ok, media_item}

          error ->
            error
        end

      {:error, reason} ->
        {:error, {:metadata_fetch_failed, reason}}
    end
  end

  defp update_existing_media_item(existing_item, provider_id, media_type, config) do
    Logger.debug("Updating existing media item",
      id: existing_item.id,
      provider_id: provider_id
    )

    case fetch_full_metadata(provider_id, media_type, config) do
      {:ok, full_metadata} ->
        attrs = build_media_item_attrs(full_metadata, media_type, %{})
        Media.update_media_item(existing_item, attrs)

      {:error, reason} ->
        Logger.warning("Failed to fetch updated metadata, returning existing item",
          id: existing_item.id,
          reason: reason
        )

        {:ok, existing_item}
    end
  end

  defp fetch_full_metadata(provider_id, media_type, config) do
    fetch_opts = [
      media_type: media_type,
      append_to_response: ["credits", "images", "videos", "keywords"]
    ]

    Metadata.fetch_by_id(config, provider_id, fetch_opts)
  end

  defp build_media_item_attrs(metadata, media_type, match_result) do
    %{
      type: media_type_to_string(media_type),
      title: metadata.title,
      original_title: metadata.original_title,
      year: extract_year(metadata),
      tmdb_id: String.to_integer(to_string(metadata.provider_id)),
      imdb_id: metadata.imdb_id,
      metadata: metadata,
      monitored: true
    }
    |> maybe_add_quality_profile(match_result)
  end

  defp media_type_to_string(:movie), do: "movie"
  defp media_type_to_string(:tv_show), do: "tv_show"

  defp extract_year(metadata) do
    cond do
      metadata.release_date ->
        extract_year_from_date(metadata.release_date)

      metadata.first_air_date ->
        extract_year_from_date(metadata.first_air_date)

      true ->
        nil
    end
  rescue
    _ -> nil
  end

  defp extract_year_from_date(%Date{} = date), do: date.year

  defp extract_year_from_date(date_string) when is_binary(date_string) do
    date_string
    |> String.slice(0..3)
    |> String.to_integer()
  end

  defp extract_year_from_date(_), do: nil

  defp maybe_add_quality_profile(attrs, %{parsed_info: %{quality: quality}})
       when map_size(quality) > 0 do
    # For now, use default quality profile
    # In the future, we could match quality to profiles
    attrs
  end

  defp maybe_add_quality_profile(attrs, _match_result), do: attrs

  defp associate_media_file(media_item, media_file_id) do
    # Update the media file to associate it with this media item
    media_file = Mydia.Library.get_media_file!(media_file_id)
    Mydia.Library.update_media_file(media_file, %{media_item_id: media_item.id})

    Logger.debug("Associated media file with media item",
      media_file_id: media_file_id,
      media_item_id: media_item.id
    )
  rescue
    _ -> :ok
  end

  defp enrich_episodes(media_item, provider_id, config, match_result) do
    Logger.info("Fetching episodes for TV show",
      media_item_id: media_item.id,
      title: media_item.title
    )

    # Get number of seasons from metadata
    num_seasons = get_number_of_seasons(media_item.metadata)

    if num_seasons && num_seasons > 0 do
      # Fetch and create/update all episodes
      Enum.each(1..num_seasons, fn season_num ->
        case Metadata.fetch_season(config, provider_id, season_num) do
          {:ok, season_data} ->
            create_episodes_for_season(media_item, season_data)

          {:error, reason} ->
            Logger.warning("Failed to fetch season data",
              media_item_id: media_item.id,
              season: season_num,
              reason: reason
            )
        end
      end)

      # After all episodes are created, directly associate the file with the target episode(s)
      # This is O(1) per episode instead of O(n) iteration through all episodes
      associate_file_with_target_episodes(media_item, match_result)
    else
      Logger.warning("No season information available",
        media_item_id: media_item.id
      )
    end

    :ok
  end

  defp get_number_of_seasons(%{number_of_seasons: num}) when is_integer(num), do: num

  defp get_number_of_seasons(%{seasons: seasons}) when is_list(seasons) do
    # Filter out season 0 (specials) for now
    Enum.count(seasons, fn s -> Map.get(s, :season_number, 0) > 0 end)
  end

  defp get_number_of_seasons(_), do: nil

  defp create_episodes_for_season(media_item, season_data) do
    episodes = Map.get(season_data, :episodes, [])
    season_number = Map.get(season_data, :season_number)

    Enum.each(episodes, fn episode_data ->
      # Check if episode already exists
      case get_episode(media_item.id, season_number, episode_data.episode_number) do
        nil ->
          attrs = build_episode_attrs(media_item.id, season_number, episode_data)

          case Media.create_episode(attrs) do
            {:ok, _episode} ->
              Logger.debug("Created episode",
                media_item_id: media_item.id,
                season: season_number,
                episode: episode_data.episode_number
              )

            {:error, reason} ->
              Logger.warning("Failed to create episode",
                media_item_id: media_item.id,
                season: season_number,
                episode: episode_data.episode_number,
                reason: reason
              )
          end

        existing_episode ->
          # Update existing episode with fresh metadata
          attrs = build_episode_attrs(media_item.id, season_number, episode_data)

          case Media.update_episode(existing_episode, attrs) do
            {:ok, _updated_episode} ->
              Logger.debug("Updated episode",
                media_item_id: media_item.id,
                season: season_number,
                episode: episode_data.episode_number
              )

            {:error, reason} ->
              Logger.warning("Failed to update episode",
                media_item_id: media_item.id,
                season: season_number,
                episode: episode_data.episode_number,
                reason: reason
              )
          end
      end
    end)
  end

  defp get_episode(media_item_id, season_number, episode_number) do
    Media.get_episode_by_number(media_item_id, season_number, episode_number)
  rescue
    _ -> nil
  end

  defp build_episode_attrs(media_item_id, season_number, episode_data) do
    %{
      media_item_id: media_item_id,
      season_number: season_number,
      episode_number: episode_data.episode_number,
      title: episode_data.name,
      air_date: parse_air_date(episode_data.air_date),
      metadata: episode_data,
      monitored: true
    }
  end

  defp parse_air_date(nil), do: nil
  defp parse_air_date(""), do: nil

  defp parse_air_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_air_date(_), do: nil

  # Directly associates the media file with target episodes using O(1) lookups
  # instead of iterating through all episodes
  defp associate_file_with_target_episodes(
         media_item,
         %{
           parsed_info: %{season: season, episodes: episode_numbers},
           media_file_id: media_file_id
         }
       )
       when is_binary(media_file_id) and is_list(episode_numbers) do
    Logger.info("Associating file with target episodes via direct lookup",
      media_item_id: media_item.id,
      season: season,
      episode_numbers: episode_numbers,
      media_file_id: media_file_id
    )

    # Direct lookup for each target episode - O(k) where k is the number of episodes in the file
    # Typically k=1, sometimes k=2 for double episodes
    Enum.each(episode_numbers, fn episode_number ->
      case Media.get_episode_by_number(media_item.id, season, episode_number) do
        nil ->
          Logger.warning("Target episode not found for file association",
            media_item_id: media_item.id,
            season: season,
            episode: episode_number
          )

        episode ->
          associate_media_file_with_episode(episode, media_file_id)
      end
    end)
  end

  defp associate_file_with_target_episodes(_media_item, match_result) do
    # No media_file_id or parsed_info - nothing to associate
    Logger.debug("Skipping file association - no media_file_id or parsed episode info",
      has_media_file_id: Map.has_key?(match_result, :media_file_id),
      has_parsed_info: Map.has_key?(match_result, :parsed_info)
    )

    :ok
  end

  defp associate_media_file_with_episode(episode, media_file_id) do
    media_file =
      Mydia.Library.get_media_file!(media_file_id)
      |> Mydia.Repo.preload(:library_path)

    case Mydia.Library.update_media_file(media_file, %{episode_id: episode.id}) do
      {:ok, _updated_file} ->
        Logger.info("Associated file with episode",
          episode_id: episode.id,
          season: episode.season_number,
          episode: episode.episode_number,
          media_file_id: media_file_id
        )

      {:error, changeset} ->
        Logger.error("Failed to associate file with episode",
          episode_id: episode.id,
          media_file_id: media_file_id,
          errors: inspect(changeset.errors)
        )
    end
  rescue
    error ->
      Logger.error("Exception associating file with episode",
        episode_id: episode.id,
        media_file_id: media_file_id,
        error: inspect(error)
      )

      :ok
  end

  # Validates that the media type is compatible with the library path type
  defp validate_library_type_compatibility(_media_type, nil) do
    # No media file, skip validation
    :ok
  end

  defp validate_library_type_compatibility(media_type, media_file_id)
       when is_binary(media_file_id) do
    case Mydia.Repo.get(Mydia.Library.MediaFile, media_file_id)
         |> Mydia.Repo.preload(:library_path) do
      nil ->
        # Media file not found, let it proceed (will fail later with better error)
        :ok

      media_file ->
        validate_media_type_against_library_path(media_type, media_file)
    end
  rescue
    error ->
      Logger.error("Exception during library type validation",
        media_type: media_type,
        media_file_id: media_file_id,
        error: inspect(error)
      )

      # Allow to proceed if validation itself fails
      :ok
  end

  defp validate_media_type_against_library_path(media_type, media_file) do
    absolute_path = Mydia.Library.MediaFile.absolute_path(media_file)
    library_path = find_library_path_for_file(absolute_path)
    media_type_string = media_type_to_string(media_type)

    cond do
      # No library path found, allow the operation
      is_nil(library_path) ->
        :ok

      # Library is :mixed, allow both types
      library_path.type == :mixed ->
        :ok

      # Movie in :series library
      media_type_string == "movie" and library_path.type == :series ->
        emit_type_mismatch_telemetry(media_type_string, library_path)

        Logger.warning("Type mismatch: Cannot add movies to series-only library",
          media_type: media_type_string,
          library_path: library_path.path,
          library_type: library_path.type,
          file_path: absolute_path
        )

        {:error,
         {:library_type_mismatch,
          "Cannot add movies to a library path configured for TV series only (path: #{library_path.path})"}}

      # TV show in :movies library
      media_type_string == "tv_show" and library_path.type == :movies ->
        emit_type_mismatch_telemetry(media_type_string, library_path)

        Logger.warning("Type mismatch: Cannot add TV shows to movies-only library",
          media_type: media_type_string,
          library_path: library_path.path,
          library_type: library_path.type,
          file_path: absolute_path
        )

        {:error,
         {:library_type_mismatch,
          "Cannot add TV shows to a library path configured for movies only (path: #{library_path.path})"}}

      # All other cases are valid
      true ->
        :ok
    end
  end

  # Finds the library path that contains the given file path
  # Prefers the longest matching prefix (most specific path)
  defp find_library_path_for_file(file_path) do
    library_paths = Settings.list_library_paths()

    library_paths
    |> Enum.filter(fn library_path ->
      String.starts_with?(file_path, library_path.path)
    end)
    |> Enum.max_by(
      fn library_path -> String.length(library_path.path) end,
      fn -> nil end
    )
  end

  # Emits telemetry event for type mismatch tracking
  defp emit_type_mismatch_telemetry(media_type, library_path) do
    :telemetry.execute(
      [:mydia, :library, :type_mismatch],
      %{count: 1},
      %{
        media_type: media_type,
        library_type: library_path.type,
        library_path: library_path.path
      }
    )
  end
end
