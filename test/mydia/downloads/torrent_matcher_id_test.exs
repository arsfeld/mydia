defmodule Mydia.Downloads.TorrentMatcherIdTest do
  use Mydia.DataCase, async: true

  alias Mydia.Downloads.TorrentMatcher
  import Mydia.Factory

  describe "ID-based matching - TMDB ID" do
    test "matches movie by TMDB ID with high confidence" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix",
          year: 1999,
          tmdb_id: 603,
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Matrix 1999 1080p BluRay",
        year: 1999,
        quality: "1080p",
        tmdb_id: 603
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      # ID-based matches should have 0.98 confidence
      assert match.confidence == 0.98
      assert match.match_reason =~ "ID-matched"
      assert match.match_reason =~ "TMDB ID 603"
    end

    test "prefers TMDB ID match over title match even with different title" do
      # Create two movies with similar titles but different TMDB IDs
      matrix =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix",
          year: 1999,
          tmdb_id: 603,
          monitored: true
        })

      matrix_reloaded =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix Reloaded",
          year: 2003,
          tmdb_id: 604,
          monitored: true
        })

      # Torrent has title similar to "Matrix" but TMDB ID for "Matrix Reloaded"
      torrent_info = %{
        type: :movie,
        title: "Matrix 1080p",
        year: 2003,
        quality: "1080p",
        tmdb_id: 604
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      # Should match Matrix Reloaded based on TMDB ID, not Matrix based on title
      assert match.media_item.id == matrix_reloaded.id
      assert match.confidence == 0.98
    end

    test "rejects match when TMDB ID doesn't match any library item" do
      insert(:media_item, %{
        type: "movie",
        title: "The Matrix",
        year: 1999,
        tmdb_id: 603,
        monitored: true
      })

      # Torrent has different TMDB ID
      torrent_info = %{
        type: :movie,
        title: "The Matrix",
        year: 1999,
        quality: "1080p",
        tmdb_id: 999_999
      }

      # Should fall back to title matching in this case
      # But since title similarity is high, it might still match
      # Let's use a threshold that would require the ID match
      assert {:error, :no_match_found} =
               TorrentMatcher.find_match(torrent_info, require_id_match: true)
    end

    test "TV show matches by TMDB ID" do
      tv_show =
        insert(:media_item, %{
          type: "tv_show",
          title: "Breaking Bad",
          tmdb_id: 1396,
          monitored: true
        })

      episode =
        insert(:episode, %{
          media_item: tv_show,
          season_number: 1,
          episode_number: 1
        })

      torrent_info = %{
        type: :tv,
        title: "Breaking.Bad.S01E01.1080p",
        season: 1,
        episode: 1,
        quality: "1080p",
        tmdb_id: 1396
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == tv_show.id
      assert match.episode.id == episode.id
      assert match.confidence == 0.98
      assert match.match_reason =~ "ID-matched"
    end

    test "season pack matches by TMDB ID" do
      tv_show =
        insert(:media_item, %{
          type: "tv_show",
          title: "House of the Dragon",
          tmdb_id: 94997,
          monitored: true
        })

      torrent_info = %{
        type: :tv_season,
        title: "House.of.the.Dragon.S01.COMPLETE.2160p",
        season: 1,
        season_pack: true,
        quality: "2160p",
        tmdb_id: 94997
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == tv_show.id
      assert match.episode == nil
      assert match.confidence == 0.98
    end
  end

  describe "ID-based matching - IMDB ID" do
    test "matches movie by IMDB ID with high confidence" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Inception",
          year: 2010,
          imdb_id: "tt1375666",
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Inception 2010 1080p",
        year: 2010,
        quality: "1080p",
        imdb_id: "tt1375666"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      assert match.confidence == 0.98
      assert match.match_reason =~ "IMDB ID tt1375666"
    end

    test "prefers TMDB ID over IMDB ID when both available" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix",
          year: 1999,
          tmdb_id: 603,
          imdb_id: "tt0133093",
          monitored: true
        })

      # Create another movie with same IMDB but different TMDB (hypothetical scenario)
      other_movie =
        insert(:media_item, %{
          type: "movie",
          title: "Other Movie",
          year: 2000,
          tmdb_id: 999,
          imdb_id: "tt9999999",
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Matrix",
        year: 1999,
        quality: "1080p",
        tmdb_id: 603,
        imdb_id: "tt9999999"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      # Should match by TMDB ID (603) not IMDB ID
      assert match.media_item.id == movie.id
      assert match.match_reason =~ "TMDB ID 603"
    end

    test "TV show matches by IMDB ID" do
      tv_show =
        insert(:media_item, %{
          type: "tv_show",
          title: "Game of Thrones",
          imdb_id: "tt0944947",
          monitored: true
        })

      episode =
        insert(:episode, %{
          media_item: tv_show,
          season_number: 1,
          episode_number: 1
        })

      torrent_info = %{
        type: :tv,
        title: "Game.of.Thrones.S01E01",
        season: 1,
        episode: 1,
        quality: "720p",
        imdb_id: "tt0944947"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == tv_show.id
      assert match.episode.id == episode.id
      assert match.confidence == 0.98
    end
  end

  describe "ID-based matching - fallback to title matching" do
    test "falls back to title matching when no IDs provided" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix",
          year: 1999,
          tmdb_id: 603,
          monitored: true
        })

      # Torrent has no IDs
      torrent_info = %{
        type: :movie,
        title: "The Matrix",
        year: 1999,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      # Perfect title/year match can have high confidence, but should not be ID-based
      # Should not mention ID in match reason
      refute match.match_reason =~ "ID-matched"
      refute match.match_reason =~ "TMDB ID"
      refute match.match_reason =~ "IMDB ID"
    end

    test "falls back to title matching when ID doesn't match any item" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Inception",
          year: 2010,
          tmdb_id: 27205,
          monitored: true
        })

      # Torrent has wrong TMDB ID but correct title
      torrent_info = %{
        type: :movie,
        title: "Inception",
        year: 2010,
        quality: "1080p",
        tmdb_id: 999_999
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      # Should match by title, not ID
      refute match.match_reason =~ "ID-matched"
    end

    test "respects require_id_match option" do
      insert(:media_item, %{
        type: "movie",
        title: "Inception",
        year: 2010,
        tmdb_id: 27205,
        monitored: true
      })

      # Torrent has no IDs
      torrent_info = %{
        type: :movie,
        title: "Inception",
        year: 2010,
        quality: "1080p"
      }

      # With require_id_match: true, should reject even though title matches
      assert {:error, :no_match_found} =
               TorrentMatcher.find_match(torrent_info, require_id_match: true)
    end
  end

  describe "ID-based matching - edge cases" do
    test "handles nil TMDB ID gracefully" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Old Movie",
          year: 1950,
          tmdb_id: nil,
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Old Movie",
        year: 1950,
        quality: "720p",
        tmdb_id: nil
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      # Should use title matching
      refute match.match_reason =~ "ID-matched"
    end

    test "handles zero TMDB ID as no ID" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Test Movie",
          year: 2020,
          tmdb_id: 100,
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Test Movie",
        year: 2020,
        quality: "1080p",
        tmdb_id: 0
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      # Should fall back to title matching
      refute match.match_reason =~ "ID-matched"
    end

    test "handles empty IMDB ID string as no ID" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Test Movie",
          year: 2020,
          imdb_id: "tt1234567",
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Test Movie",
        year: 2020,
        quality: "1080p",
        imdb_id: ""
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      # Should fall back to title matching
      refute match.match_reason =~ "ID-matched"
    end

    test "prevents wrong sequels from matching via ID validation" do
      matrix =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix",
          year: 1999,
          tmdb_id: 603,
          monitored: true
        })

      matrix_reloaded =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix Reloaded",
          year: 2003,
          tmdb_id: 604,
          monitored: true
        })

      # Torrent for Matrix but user only has Matrix Reloaded
      torrent_info = %{
        type: :movie,
        title: "The Matrix 1999 1080p",
        year: 1999,
        quality: "1080p",
        tmdb_id: 603
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      # Should correctly match The Matrix, not The Matrix Reloaded
      assert match.media_item.id == matrix.id
      assert match.media_item.title == "The Matrix"
    end
  end

  describe "ID-based matching - TV episode not found" do
    test "returns error when episode not found even with ID match" do
      tv_show =
        insert(:media_item, %{
          type: "tv_show",
          title: "Breaking Bad",
          tmdb_id: 1396,
          monitored: true
        })

      # No episodes inserted

      torrent_info = %{
        type: :tv,
        title: "Breaking.Bad.S05E16.1080p",
        season: 5,
        episode: 16,
        quality: "1080p",
        tmdb_id: 1396
      }

      # Show matches but episode doesn't exist
      assert {:error, :episode_not_found} = TorrentMatcher.find_match(torrent_info)
    end
  end
end
