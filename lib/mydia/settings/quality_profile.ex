defmodule Mydia.Settings.QualityProfile do
  @moduledoc """
  Schema for quality profiles that define acceptable quality levels for media.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Allowed values for quality standards validation
  @valid_video_codecs [
    "h264",
    "h265",
    "hevc",
    "x264",
    "x265",
    "av1",
    "vc1",
    "mpeg2",
    "xvid",
    "divx"
  ]
  @valid_audio_codecs [
    "aac",
    "ac3",
    "eac3",
    "dts",
    "dts-hd",
    "truehd",
    "atmos",
    "flac",
    "mp3",
    "opus"
  ]
  @valid_audio_channels ["1.0", "2.0", "2.1", "5.1", "6.1", "7.1", "7.1.2", "7.1.4"]
  @valid_resolutions ["360p", "480p", "576p", "720p", "1080p", "2160p", "4320p"]
  @valid_sources [
    "BluRay",
    "REMUX",
    "WEB-DL",
    "WEBRip",
    "HDTV",
    "SDTV",
    "DVD",
    "DVDRip",
    "BDRip"
  ]
  @valid_hdr_formats ["hdr10", "hdr10+", "dolby_vision", "hlg"]

  schema "quality_profiles" do
    field :name, :string
    field :upgrades_allowed, :boolean, default: true
    field :upgrade_until_quality, :string
    field :qualities, {:array, :string}
    # Rules can contain arbitrary filtering rules, including:
    # - min_ratio: Minimum seeder/leecher ratio (e.g., 0.15 for 15%)
    field :rules, :map

    # Enhanced fields for import/export and configuration management
    field :description, :string
    field :is_system, :boolean, default: false
    field :version, :integer, default: 1
    field :source_url, :string
    field :last_synced_at, :utc_datetime
    field :quality_standards, :map
    field :metadata_preferences, :map
    field :customizations, :map

    has_many :media_files, Mydia.Library.MediaFile

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a quality profile.
  """
  def changeset(quality_profile, attrs) do
    quality_profile
    |> cast(attrs, [
      :name,
      :upgrades_allowed,
      :upgrade_until_quality,
      :qualities,
      :rules,
      :description,
      :is_system,
      :version,
      :source_url,
      :last_synced_at,
      :quality_standards,
      :metadata_preferences,
      :customizations
    ])
    |> validate_required([:name, :qualities])
    |> validate_length(:qualities, min: 1)
    |> unique_constraint(:name)
    |> validate_quality_standards()
    |> validate_metadata_preferences()
  end

  @doc """
  Validates the quality_standards map structure and values.

  Expected structure:
  %{
    # Video codec preferences (priority ordered, first = most preferred)
    preferred_video_codecs: ["h265", "h264", "av1"],

    # Audio codec preferences (priority ordered, first = most preferred)
    preferred_audio_codecs: ["atmos", "truehd", "dts-hd", "ac3"],

    # Audio channel preferences (priority ordered)
    preferred_audio_channels: ["7.1", "5.1", "2.0"],

    # Resolution preferences (min/max/preferred)
    min_resolution: "720p",
    max_resolution: "2160p",
    preferred_resolutions: ["1080p", "2160p"],

    # Source preferences (priority ordered)
    preferred_sources: ["BluRay", "REMUX", "WEB-DL"],

    # Video bitrate ranges (Mbps)
    min_video_bitrate_mbps: 5.0,
    max_video_bitrate_mbps: 50.0,
    preferred_video_bitrate_mbps: 15.0,

    # Audio bitrate ranges (kbps)
    min_audio_bitrate_kbps: 128,
    max_audio_bitrate_kbps: 768,
    preferred_audio_bitrate_kbps: 320,

    # File size guidelines (MB) - differentiated by media type
    movie_min_size_mb: 2048,
    movie_max_size_mb: 15360,
    episode_min_size_mb: 512,
    episode_max_size_mb: 4096,

    # HDR/Dolby Vision preferences
    hdr_formats: ["dolby_vision", "hdr10+", "hdr10"],
    require_hdr: false
  }
  """
  def validate_quality_standards(changeset) do
    case get_change(changeset, :quality_standards) do
      nil ->
        changeset

      standards when is_map(standards) ->
        changeset
        |> validate_video_codecs(standards)
        |> validate_audio_codecs(standards)
        |> validate_audio_channels(standards)
        |> validate_resolution_ranges(standards)
        |> validate_resolutions(standards)
        |> validate_sources(standards)
        |> validate_video_bitrates(standards)
        |> validate_audio_bitrates(standards)
        |> validate_media_type_sizes(standards)
        |> validate_hdr_formats(standards)

      _ ->
        add_error(changeset, :quality_standards, "must be a map")
    end
  end

  @doc """
  Validates the metadata_preferences map structure and values.

  Expected structure:
  %{
    # Provider priority list - ordered list of providers to try in sequence
    provider_priority: ["metadata_relay", "tvdb", "tmdb"],

    # Per-field provider mapping - override specific fields to use specific providers
    field_providers: %{
      "title" => "tvdb",
      "overview" => "tmdb",
      "poster" => "tmdb",
      "backdrop" => "tmdb"
    },

    # Language and region preferences
    language: "en-US",
    region: "US",
    fallback_languages: ["en", "ja"],

    # Auto-fetch settings
    auto_fetch_enabled: true,
    auto_refresh_interval_hours: 168,  # 7 days

    # Fallback behavior
    fallback_on_provider_failure: true,
    skip_unavailable_providers: true,

    # Conflict resolution
    conflict_resolution: "prefer_newer",  # "prefer_newer", "prefer_older", "manual"
    merge_strategy: "union"  # "union", "intersection", "priority"
  }
  """
  def validate_metadata_preferences(changeset) do
    case get_change(changeset, :metadata_preferences) do
      nil ->
        changeset

      prefs when is_map(prefs) ->
        changeset
        |> validate_provider_priority(prefs)
        |> validate_field_providers(prefs)
        |> validate_language_settings(prefs)
        |> validate_auto_fetch_settings(prefs)
        |> validate_fallback_settings(prefs)
        |> validate_conflict_resolution(prefs)

      _ ->
        add_error(changeset, :metadata_preferences, "must be a map")
    end
  end

  @doc """
  Calculates a quality score for a media file based on the profile's quality standards.

  Returns a score between 0.0 and 100.0, where:
  - 100.0 = Perfect match for all criteria
  - 0.0 = Does not meet any criteria or violates constraints

  ## Parameters

    - `profile` - QualityProfile struct with quality_standards defined
    - `media_attrs` - Map containing media file attributes:
      - `:video_codec` - Video codec (e.g., "h265", "h264")
      - `:audio_codec` - Audio codec (e.g., "atmos", "ac3")
      - `:audio_channels` - Audio channels (e.g., "5.1", "7.1")
      - `:resolution` - Resolution (e.g., "1080p", "2160p")
      - `:source` - Source type (e.g., "BluRay", "WEB-DL")
      - `:video_bitrate_mbps` - Video bitrate in Mbps
      - `:audio_bitrate_kbps` - Audio bitrate in kbps
      - `:file_size_mb` - File size in MB
      - `:media_type` - Either :movie or :episode
      - `:hdr_format` - HDR format if present (e.g., "dolby_vision", "hdr10")

  ## Returns

    A map with:
    - `:score` - Overall quality score (0.0 - 100.0)
    - `:breakdown` - Map with individual component scores
    - `:violations` - List of constraint violations (if any)

  ## Examples

      iex> score_media_file(profile, %{
        video_codec: "h265",
        audio_codec: "atmos",
        resolution: "1080p",
        file_size_mb: 8192,
        media_type: :movie
      })
      %{
        score: 95.5,
        breakdown: %{video_codec: 100.0, audio_codec: 100.0, ...},
        violations: []
      }
  """
  def score_media_file(%__MODULE__{quality_standards: nil}, _media_attrs) do
    %{score: 0.0, breakdown: %{}, violations: ["No quality standards defined"]}
  end

  def score_media_file(%__MODULE__{quality_standards: standards}, media_attrs) do
    # Calculate individual component scores
    video_codec_score = score_video_codec(standards, media_attrs)
    audio_codec_score = score_audio_codec(standards, media_attrs)
    audio_channels_score = score_audio_channels(standards, media_attrs)
    resolution_score = score_resolution(standards, media_attrs)
    source_score = score_source(standards, media_attrs)
    video_bitrate_score = score_video_bitrate(standards, media_attrs)
    audio_bitrate_score = score_audio_bitrate(standards, media_attrs)
    file_size_score = score_file_size(standards, media_attrs)
    hdr_score = score_hdr_format(standards, media_attrs)

    # Collect violations
    violations = collect_violations(standards, media_attrs)

    # If there are hard violations, return 0 score
    if violations != [] do
      %{
        score: 0.0,
        breakdown: %{
          video_codec: video_codec_score,
          audio_codec: audio_codec_score,
          audio_channels: audio_channels_score,
          resolution: resolution_score,
          source: source_score,
          video_bitrate: video_bitrate_score,
          audio_bitrate: audio_bitrate_score,
          file_size: file_size_score,
          hdr: hdr_score
        },
        violations: violations
      }
    else
      # Calculate weighted average
      # Weights are somewhat arbitrary but prioritize codec and resolution
      weights = %{
        video_codec: 0.20,
        audio_codec: 0.15,
        audio_channels: 0.10,
        resolution: 0.20,
        source: 0.10,
        video_bitrate: 0.10,
        audio_bitrate: 0.05,
        file_size: 0.05,
        hdr: 0.05
      }

      total_score =
        video_codec_score * weights.video_codec +
          audio_codec_score * weights.audio_codec +
          audio_channels_score * weights.audio_channels +
          resolution_score * weights.resolution +
          source_score * weights.source +
          video_bitrate_score * weights.video_bitrate +
          audio_bitrate_score * weights.audio_bitrate +
          file_size_score * weights.file_size +
          hdr_score * weights.hdr

      %{
        score: Float.round(total_score, 1),
        breakdown: %{
          video_codec: video_codec_score,
          audio_codec: audio_codec_score,
          audio_channels: audio_channels_score,
          resolution: resolution_score,
          source: source_score,
          video_bitrate: video_bitrate_score,
          audio_bitrate: audio_bitrate_score,
          file_size: file_size_score,
          hdr: hdr_score
        },
        violations: []
      }
    end
  end

  # Private validation helpers

  defp validate_video_codecs(changeset, standards) do
    case Map.get(standards, :preferred_video_codecs) do
      nil ->
        changeset

      codecs when is_list(codecs) ->
        invalid_codecs = codecs -- @valid_video_codecs

        if Enum.empty?(invalid_codecs) do
          changeset
        else
          add_error(
            changeset,
            :quality_standards,
            "contains invalid video codecs: #{Enum.join(invalid_codecs, ", ")}. " <>
              "Valid codecs: #{Enum.join(@valid_video_codecs, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :quality_standards, "preferred_video_codecs must be a list")
    end
  end

  defp validate_audio_codecs(changeset, standards) do
    case Map.get(standards, :preferred_audio_codecs) do
      nil ->
        changeset

      codecs when is_list(codecs) ->
        invalid_codecs = codecs -- @valid_audio_codecs

        if Enum.empty?(invalid_codecs) do
          changeset
        else
          add_error(
            changeset,
            :quality_standards,
            "contains invalid audio codecs: #{Enum.join(invalid_codecs, ", ")}. " <>
              "Valid codecs: #{Enum.join(@valid_audio_codecs, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :quality_standards, "preferred_audio_codecs must be a list")
    end
  end

  defp validate_audio_channels(changeset, standards) do
    case Map.get(standards, :preferred_audio_channels) do
      nil ->
        changeset

      channels when is_list(channels) ->
        invalid_channels = channels -- @valid_audio_channels

        if Enum.empty?(invalid_channels) do
          changeset
        else
          add_error(
            changeset,
            :quality_standards,
            "contains invalid audio channels: #{Enum.join(invalid_channels, ", ")}. " <>
              "Valid channels: #{Enum.join(@valid_audio_channels, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :quality_standards, "preferred_audio_channels must be a list")
    end
  end

  defp validate_resolution_ranges(changeset, standards) do
    min_resolution = Map.get(standards, :min_resolution)
    max_resolution = Map.get(standards, :max_resolution)

    changeset =
      if min_resolution && min_resolution not in @valid_resolutions do
        add_error(
          changeset,
          :quality_standards,
          "min_resolution must be one of: #{Enum.join(@valid_resolutions, ", ")}"
        )
      else
        changeset
      end

    changeset =
      if max_resolution && max_resolution not in @valid_resolutions do
        add_error(
          changeset,
          :quality_standards,
          "max_resolution must be one of: #{Enum.join(@valid_resolutions, ", ")}"
        )
      else
        changeset
      end

    # Validate min <= max resolution
    if min_resolution && max_resolution do
      min_index = Enum.find_index(@valid_resolutions, &(&1 == min_resolution))
      max_index = Enum.find_index(@valid_resolutions, &(&1 == max_resolution))

      if min_index && max_index && min_index > max_index do
        add_error(
          changeset,
          :quality_standards,
          "min_resolution (#{min_resolution}) cannot be greater than max_resolution (#{max_resolution})"
        )
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_resolutions(changeset, standards) do
    case Map.get(standards, :preferred_resolutions) do
      nil ->
        changeset

      resolutions when is_list(resolutions) ->
        invalid_resolutions = resolutions -- @valid_resolutions

        if Enum.empty?(invalid_resolutions) do
          changeset
        else
          add_error(
            changeset,
            :quality_standards,
            "contains invalid resolutions: #{Enum.join(invalid_resolutions, ", ")}. " <>
              "Valid resolutions: #{Enum.join(@valid_resolutions, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :quality_standards, "preferred_resolutions must be a list")
    end
  end

  defp validate_sources(changeset, standards) do
    case Map.get(standards, :preferred_sources) do
      nil ->
        changeset

      sources when is_list(sources) ->
        invalid_sources = sources -- @valid_sources

        if Enum.empty?(invalid_sources) do
          changeset
        else
          add_error(
            changeset,
            :quality_standards,
            "contains invalid sources: #{Enum.join(invalid_sources, ", ")}. " <>
              "Valid sources: #{Enum.join(@valid_sources, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :quality_standards, "preferred_sources must be a list")
    end
  end

  defp validate_video_bitrates(changeset, standards) do
    min_bitrate = Map.get(standards, :min_video_bitrate_mbps)
    max_bitrate = Map.get(standards, :max_video_bitrate_mbps)
    preferred_bitrate = Map.get(standards, :preferred_video_bitrate_mbps)

    changeset =
      if min_bitrate && !is_number(min_bitrate) do
        add_error(changeset, :quality_standards, "min_video_bitrate_mbps must be a number")
      else
        changeset
      end

    changeset =
      if max_bitrate && !is_number(max_bitrate) do
        add_error(changeset, :quality_standards, "max_video_bitrate_mbps must be a number")
      else
        changeset
      end

    changeset =
      if preferred_bitrate && !is_number(preferred_bitrate) do
        add_error(changeset, :quality_standards, "preferred_video_bitrate_mbps must be a number")
      else
        changeset
      end

    changeset =
      if min_bitrate && max_bitrate && min_bitrate > max_bitrate do
        add_error(
          changeset,
          :quality_standards,
          "min_video_bitrate_mbps cannot be greater than max_video_bitrate_mbps"
        )
      else
        changeset
      end

    # Validate preferred is within range
    if preferred_bitrate && min_bitrate && preferred_bitrate < min_bitrate do
      add_error(
        changeset,
        :quality_standards,
        "preferred_video_bitrate_mbps cannot be less than min_video_bitrate_mbps"
      )
    else
      if preferred_bitrate && max_bitrate && preferred_bitrate > max_bitrate do
        add_error(
          changeset,
          :quality_standards,
          "preferred_video_bitrate_mbps cannot be greater than max_video_bitrate_mbps"
        )
      else
        changeset
      end
    end
  end

  defp validate_audio_bitrates(changeset, standards) do
    min_bitrate = Map.get(standards, :min_audio_bitrate_kbps)
    max_bitrate = Map.get(standards, :max_audio_bitrate_kbps)
    preferred_bitrate = Map.get(standards, :preferred_audio_bitrate_kbps)

    changeset =
      if min_bitrate && !is_integer(min_bitrate) do
        add_error(changeset, :quality_standards, "min_audio_bitrate_kbps must be an integer")
      else
        changeset
      end

    changeset =
      if max_bitrate && !is_integer(max_bitrate) do
        add_error(changeset, :quality_standards, "max_audio_bitrate_kbps must be an integer")
      else
        changeset
      end

    changeset =
      if preferred_bitrate && !is_integer(preferred_bitrate) do
        add_error(
          changeset,
          :quality_standards,
          "preferred_audio_bitrate_kbps must be an integer"
        )
      else
        changeset
      end

    changeset =
      if min_bitrate && max_bitrate && min_bitrate > max_bitrate do
        add_error(
          changeset,
          :quality_standards,
          "min_audio_bitrate_kbps cannot be greater than max_audio_bitrate_kbps"
        )
      else
        changeset
      end

    # Validate preferred is within range
    if preferred_bitrate && min_bitrate && preferred_bitrate < min_bitrate do
      add_error(
        changeset,
        :quality_standards,
        "preferred_audio_bitrate_kbps cannot be less than min_audio_bitrate_kbps"
      )
    else
      if preferred_bitrate && max_bitrate && preferred_bitrate > max_bitrate do
        add_error(
          changeset,
          :quality_standards,
          "preferred_audio_bitrate_kbps cannot be greater than max_audio_bitrate_kbps"
        )
      else
        changeset
      end
    end
  end

  defp validate_media_type_sizes(changeset, standards) do
    # Validate movie sizes
    movie_min = Map.get(standards, :movie_min_size_mb)
    movie_max = Map.get(standards, :movie_max_size_mb)

    changeset =
      if movie_min && !is_integer(movie_min) do
        add_error(changeset, :quality_standards, "movie_min_size_mb must be an integer")
      else
        changeset
      end

    changeset =
      if movie_max && !is_integer(movie_max) do
        add_error(changeset, :quality_standards, "movie_max_size_mb must be an integer")
      else
        changeset
      end

    changeset =
      if movie_min && movie_max && movie_min > movie_max do
        add_error(
          changeset,
          :quality_standards,
          "movie_min_size_mb cannot be greater than movie_max_size_mb"
        )
      else
        changeset
      end

    # Validate episode sizes
    episode_min = Map.get(standards, :episode_min_size_mb)
    episode_max = Map.get(standards, :episode_max_size_mb)

    changeset =
      if episode_min && !is_integer(episode_min) do
        add_error(changeset, :quality_standards, "episode_min_size_mb must be an integer")
      else
        changeset
      end

    changeset =
      if episode_max && !is_integer(episode_max) do
        add_error(changeset, :quality_standards, "episode_max_size_mb must be an integer")
      else
        changeset
      end

    if episode_min && episode_max && episode_min > episode_max do
      add_error(
        changeset,
        :quality_standards,
        "episode_min_size_mb cannot be greater than episode_max_size_mb"
      )
    else
      changeset
    end
  end

  defp validate_hdr_formats(changeset, standards) do
    hdr_formats = Map.get(standards, :hdr_formats)
    require_hdr = Map.get(standards, :require_hdr)

    changeset =
      case hdr_formats do
        nil ->
          changeset

        formats when is_list(formats) ->
          invalid_formats = formats -- @valid_hdr_formats

          if Enum.empty?(invalid_formats) do
            changeset
          else
            add_error(
              changeset,
              :quality_standards,
              "contains invalid HDR formats: #{Enum.join(invalid_formats, ", ")}. " <>
                "Valid formats: #{Enum.join(@valid_hdr_formats, ", ")}"
            )
          end

        _ ->
          add_error(changeset, :quality_standards, "hdr_formats must be a list")
      end

    if require_hdr && !is_boolean(require_hdr) do
      add_error(changeset, :quality_standards, "require_hdr must be a boolean")
    else
      changeset
    end
  end

  # Validation helpers for metadata_preferences

  defp validate_provider_priority(changeset, prefs) do
    case Map.get(prefs, :provider_priority) do
      nil ->
        changeset

      priority when is_list(priority) ->
        # Ensure it's a list of valid provider names (strings or atoms)
        valid_names =
          Enum.all?(priority, fn name ->
            (is_binary(name) or is_atom(name)) and valid_provider_name?(name)
          end)

        if valid_names do
          changeset
        else
          add_error(
            changeset,
            :metadata_preferences,
            "provider_priority must be a list of valid provider names (metadata_relay, tvdb, tmdb, omdb)"
          )
        end

      _ ->
        add_error(changeset, :metadata_preferences, "provider_priority must be a list")
    end
  end

  defp validate_field_providers(changeset, prefs) do
    case Map.get(prefs, :field_providers) do
      nil ->
        changeset

      field_map when is_map(field_map) ->
        # Validate that all values are valid provider names
        invalid_providers =
          field_map
          |> Map.values()
          |> Enum.reject(&valid_provider_name?/1)

        if Enum.empty?(invalid_providers) do
          changeset
        else
          add_error(
            changeset,
            :metadata_preferences,
            "field_providers contains invalid provider names: #{Enum.join(invalid_providers, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :metadata_preferences, "field_providers must be a map")
    end
  end

  defp validate_language_settings(changeset, prefs) do
    changeset
    |> validate_language_code(prefs, :language)
    |> validate_region_code(prefs)
    |> validate_fallback_languages(prefs)
  end

  defp validate_language_code(changeset, prefs, key) do
    case Map.get(prefs, key) do
      nil ->
        changeset

      lang when is_binary(lang) ->
        # Accept both ISO 639-1 (2 chars) and locale codes (e.g., "en-US")
        if valid_language_code?(lang) do
          changeset
        else
          add_error(
            changeset,
            :metadata_preferences,
            "#{key} must be a valid language code (e.g., 'en', 'ja', 'en-US', 'ja-JP')"
          )
        end

      _ ->
        add_error(changeset, :metadata_preferences, "#{key} must be a string")
    end
  end

  defp validate_region_code(changeset, prefs) do
    case Map.get(prefs, :region) do
      nil ->
        changeset

      region when is_binary(region) ->
        # Validate ISO 3166-1 alpha-2 country code (2 uppercase letters)
        if String.match?(region, ~r/^[A-Z]{2}$/) do
          changeset
        else
          add_error(
            changeset,
            :metadata_preferences,
            "region must be a 2-letter ISO 3166-1 alpha-2 country code (e.g., 'US', 'JP')"
          )
        end

      _ ->
        add_error(changeset, :metadata_preferences, "region must be a string")
    end
  end

  defp validate_fallback_languages(changeset, prefs) do
    case Map.get(prefs, :fallback_languages) do
      nil ->
        changeset

      langs when is_list(langs) ->
        if Enum.all?(langs, &valid_language_code?/1) do
          changeset
        else
          add_error(
            changeset,
            :metadata_preferences,
            "fallback_languages must be a list of valid language codes"
          )
        end

      _ ->
        add_error(changeset, :metadata_preferences, "fallback_languages must be a list")
    end
  end

  defp validate_auto_fetch_settings(changeset, prefs) do
    changeset
    |> validate_boolean_pref(prefs, :auto_fetch_enabled)
    |> validate_positive_integer(prefs, :auto_refresh_interval_hours)
  end

  defp validate_fallback_settings(changeset, prefs) do
    changeset
    |> validate_boolean_pref(prefs, :fallback_on_provider_failure)
    |> validate_boolean_pref(prefs, :skip_unavailable_providers)
  end

  defp validate_conflict_resolution(changeset, prefs) do
    changeset
    |> validate_enum_value(prefs, :conflict_resolution, ["prefer_newer", "prefer_older", "manual"])
    |> validate_enum_value(prefs, :merge_strategy, ["union", "intersection", "priority"])
  end

  # Helper validation functions

  defp validate_boolean_pref(changeset, prefs, key) do
    case Map.get(prefs, key) do
      nil -> changeset
      val when is_boolean(val) -> changeset
      _ -> add_error(changeset, :metadata_preferences, "#{key} must be a boolean")
    end
  end

  defp validate_positive_integer(changeset, prefs, key) do
    case Map.get(prefs, key) do
      nil ->
        changeset

      val when is_integer(val) and val > 0 ->
        changeset

      _ ->
        add_error(changeset, :metadata_preferences, "#{key} must be a positive integer")
    end
  end

  defp validate_enum_value(changeset, prefs, key, valid_values) do
    case Map.get(prefs, key) do
      nil ->
        changeset

      val when is_binary(val) ->
        if val in valid_values do
          changeset
        else
          add_error(
            changeset,
            :metadata_preferences,
            "#{key} must be one of: #{Enum.join(valid_values, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :metadata_preferences, "#{key} must be a string")
    end
  end

  # Provider and language code validation

  @valid_providers [
    "metadata_relay",
    "tvdb",
    "tmdb",
    "omdb",
    :metadata_relay,
    :tvdb,
    :tmdb,
    :omdb
  ]

  defp valid_provider_name?(name) when is_atom(name) do
    Atom.to_string(name) in @valid_providers
  end

  defp valid_provider_name?(name) when is_binary(name) do
    name in @valid_providers
  end

  defp valid_provider_name?(_), do: false

  defp valid_language_code?(lang) when is_binary(lang) do
    # Accept ISO 639-1 (2 chars) or locale codes (e.g., "en-US", "ja-JP")
    String.match?(lang, ~r/^[a-z]{2}(-[A-Z]{2})?$/)
  end

  defp valid_language_code?(_), do: false

  # Quality scoring helpers

  defp score_video_codec(standards, %{video_codec: codec}) when is_binary(codec) do
    case Map.get(standards, :preferred_video_codecs) do
      nil ->
        100.0

      codecs when is_list(codecs) ->
        score_from_preference_list(codec, codecs)

      _ ->
        100.0
    end
  end

  defp score_video_codec(_standards, _media_attrs), do: 50.0

  defp score_audio_codec(standards, %{audio_codec: codec}) when is_binary(codec) do
    case Map.get(standards, :preferred_audio_codecs) do
      nil ->
        100.0

      codecs when is_list(codecs) ->
        score_from_preference_list(codec, codecs)

      _ ->
        100.0
    end
  end

  defp score_audio_codec(_standards, _media_attrs), do: 50.0

  defp score_audio_channels(standards, %{audio_channels: channels}) when is_binary(channels) do
    case Map.get(standards, :preferred_audio_channels) do
      nil ->
        100.0

      channel_list when is_list(channel_list) ->
        score_from_preference_list(channels, channel_list)

      _ ->
        100.0
    end
  end

  defp score_audio_channels(_standards, _media_attrs), do: 50.0

  defp score_resolution(standards, %{resolution: resolution}) when is_binary(resolution) do
    min_resolution = Map.get(standards, :min_resolution)
    max_resolution = Map.get(standards, :max_resolution)
    preferred_resolutions = Map.get(standards, :preferred_resolutions, [])

    # Check if within range first
    score =
      cond do
        # Check preferred list
        resolution in preferred_resolutions ->
          100.0

        # Check if within min/max range
        is_within_resolution_range?(resolution, min_resolution, max_resolution) ->
          75.0

        true ->
          25.0
      end

    score
  end

  defp score_resolution(_standards, _media_attrs), do: 50.0

  defp score_source(standards, %{source: source}) when is_binary(source) do
    case Map.get(standards, :preferred_sources) do
      nil ->
        100.0

      sources when is_list(sources) ->
        score_from_preference_list(source, sources)

      _ ->
        100.0
    end
  end

  defp score_source(_standards, _media_attrs), do: 50.0

  defp score_video_bitrate(standards, %{video_bitrate_mbps: bitrate}) when is_number(bitrate) do
    min_bitrate = Map.get(standards, :min_video_bitrate_mbps)
    max_bitrate = Map.get(standards, :max_video_bitrate_mbps)
    preferred_bitrate = Map.get(standards, :preferred_video_bitrate_mbps)

    score_from_range(bitrate, min_bitrate, max_bitrate, preferred_bitrate)
  end

  defp score_video_bitrate(_standards, _media_attrs), do: 50.0

  defp score_audio_bitrate(standards, %{audio_bitrate_kbps: bitrate}) when is_number(bitrate) do
    min_bitrate = Map.get(standards, :min_audio_bitrate_kbps)
    max_bitrate = Map.get(standards, :max_audio_bitrate_kbps)
    preferred_bitrate = Map.get(standards, :preferred_audio_bitrate_kbps)

    score_from_range(bitrate, min_bitrate, max_bitrate, preferred_bitrate)
  end

  defp score_audio_bitrate(_standards, _media_attrs), do: 50.0

  defp score_file_size(standards, %{file_size_mb: size, media_type: :movie})
       when is_number(size) do
    min_size = Map.get(standards, :movie_min_size_mb)
    max_size = Map.get(standards, :movie_max_size_mb)

    score_from_range(size, min_size, max_size, nil)
  end

  defp score_file_size(standards, %{file_size_mb: size, media_type: :episode})
       when is_number(size) do
    min_size = Map.get(standards, :episode_min_size_mb)
    max_size = Map.get(standards, :episode_max_size_mb)

    score_from_range(size, min_size, max_size, nil)
  end

  defp score_file_size(_standards, _media_attrs), do: 50.0

  defp score_hdr_format(standards, %{hdr_format: format}) when is_binary(format) do
    case Map.get(standards, :hdr_formats) do
      nil ->
        100.0

      formats when is_list(formats) ->
        score_from_preference_list(format, formats)

      _ ->
        100.0
    end
  end

  defp score_hdr_format(_standards, _media_attrs), do: 50.0

  defp collect_violations(standards, media_attrs) do
    violations = []

    # Check HDR requirement
    violations =
      if Map.get(standards, :require_hdr) == true && !Map.has_key?(media_attrs, :hdr_format) do
        ["HDR is required but file does not have HDR" | violations]
      else
        violations
      end

    # Check resolution range violations
    violations =
      case {Map.get(standards, :min_resolution), Map.get(media_attrs, :resolution)} do
        {min_res, res} when is_binary(min_res) and is_binary(res) ->
          if is_below_resolution?(res, min_res) do
            ["Resolution #{res} is below minimum #{min_res}" | violations]
          else
            violations
          end

        _ ->
          violations
      end

    violations =
      case {Map.get(standards, :max_resolution), Map.get(media_attrs, :resolution)} do
        {max_res, res} when is_binary(max_res) and is_binary(res) ->
          if is_above_resolution?(res, max_res) do
            ["Resolution #{res} is above maximum #{max_res}" | violations]
          else
            violations
          end

        _ ->
          violations
      end

    violations
  end

  # Scores a value based on its position in a preference list
  # First item = 100, last item = 60, not in list = 25
  defp score_from_preference_list(value, preference_list) do
    case Enum.find_index(preference_list, &(&1 == value)) do
      nil ->
        25.0

      index ->
        # Linear decay from 100 to 60
        max_score = 100.0
        min_score = 60.0
        list_size = length(preference_list)

        if list_size == 1 do
          max_score
        else
          max_score - index * (max_score - min_score) / (list_size - 1)
        end
    end
  end

  # Scores a value based on its position within a range
  defp score_from_range(value, min_val, max_val, preferred_val) do
    cond do
      # If we have a preferred value and match it, perfect score
      preferred_val && value == preferred_val ->
        100.0

      # If we have a preferred value and are close to it (within 10%), high score
      preferred_val && abs(value - preferred_val) / preferred_val <= 0.10 ->
        95.0

      # If within min/max range, decent score
      min_val && max_val && value >= min_val && value <= max_val ->
        75.0

      # If only min is set and above it
      min_val && !max_val && value >= min_val ->
        75.0

      # If only max is set and below it
      !min_val && max_val && value <= max_val ->
        75.0

      # If no constraints are set
      !min_val && !max_val ->
        100.0

      # Otherwise, below range or above range
      true ->
        25.0
    end
  end

  defp is_within_resolution_range?(_resolution, nil, nil), do: true

  defp is_within_resolution_range?(resolution, min_res, max_res) do
    res_index = Enum.find_index(@valid_resolutions, &(&1 == resolution))
    min_index = min_res && Enum.find_index(@valid_resolutions, &(&1 == min_res))
    max_index = max_res && Enum.find_index(@valid_resolutions, &(&1 == max_res))

    cond do
      !res_index -> false
      min_index && res_index < min_index -> false
      max_index && res_index > max_index -> false
      true -> true
    end
  end

  defp is_below_resolution?(resolution, min_resolution) do
    res_index = Enum.find_index(@valid_resolutions, &(&1 == resolution))
    min_index = Enum.find_index(@valid_resolutions, &(&1 == min_resolution))

    res_index && min_index && res_index < min_index
  end

  defp is_above_resolution?(resolution, max_resolution) do
    res_index = Enum.find_index(@valid_resolutions, &(&1 == resolution))
    max_index = Enum.find_index(@valid_resolutions, &(&1 == max_resolution))

    res_index && max_index && res_index > max_index
  end
end
