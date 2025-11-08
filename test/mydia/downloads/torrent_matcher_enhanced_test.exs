defmodule Mydia.Downloads.TorrentMatcherEnhancedTest do
  @moduledoc """
  Tests for enhanced torrent matching features:
  - Unicode normalization (accents, umlauts)
  - Stricter year validation
  - Sequel marker detection
  - Word boundary checking
  """
  use Mydia.DataCase, async: true
  alias Mydia.Downloads.TorrentMatcher
  import Mydia.Factory

  describe "unicode normalization (accents and umlauts)" do
    test "matches movie titles with accented characters" do
      # Create a movie with accented title
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Amélie",
          year: 2001,
          monitored: true
        })

      # Torrent has ASCII equivalent
      torrent_info = %{
        type: :movie,
        title: "Amelie",
        year: 2001,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      assert match.confidence > 0.8
    end

    test "matches movie titles with German umlauts" do
      # Create a movie with umlauts
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Die Fälscher",
          year: 2007,
          monitored: true
        })

      # Torrent has normalized version
      torrent_info = %{
        type: :movie,
        title: "Die Faelscher",
        year: 2007,
        quality: "720p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      assert match.confidence > 0.8
    end

    test "matches movie titles with various accents" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "La Môme",
          year: 2007,
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "La Mome",
        year: 2007,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
    end
  end

  describe "stricter year validation to prevent sequels" do
    test "rejects Matrix Reloaded when searching for The Matrix" do
      # The Matrix (1999)
      insert(:media_item, %{
        type: "movie",
        title: "The Matrix",
        year: 1999,
        monitored: true
      })

      # Matrix Reloaded torrent (2003)
      torrent_info = %{
        type: :movie,
        title: "The Matrix Reloaded",
        year: 2003,
        quality: "1080p"
      }

      # Should not match due to year difference and sequel marker
      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "rejects Alien when library has Aliens" do
      # Aliens (1986)
      insert(:media_item, %{
        type: "movie",
        title: "Aliens",
        year: 1986,
        monitored: true
      })

      # Alien torrent (1979)
      torrent_info = %{
        type: :movie,
        title: "Alien",
        year: 1979,
        quality: "1080p"
      }

      # Should not match due to year difference >1
      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "accepts movie with year difference of 1" do
      # Sometimes release dates differ by a year
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Interstellar",
          year: 2014,
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Interstellar",
        year: 2015,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      # Should still have decent confidence with ±1 year
      assert match.confidence > 0.7
    end

    test "penalizes year difference >1 for similar titles" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Star Wars",
          year: 1977,
          monitored: true
        })

      # Star Wars with wrong year
      torrent_info = %{
        type: :movie,
        title: "Star Wars",
        year: 1980,
        quality: "1080p"
      }

      # Should either not match or have very low confidence
      case TorrentMatcher.find_match(torrent_info) do
        {:ok, match} ->
          assert match.media_item.id == movie.id
          # Confidence should be low due to year mismatch
          assert match.confidence < 0.5

        {:error, :no_match_found} ->
          # Also acceptable
          assert true
      end
    end
  end

  describe "sequel marker detection" do
    test "detects Roman numeral sequel markers" do
      # Original movie
      insert(:media_item, %{
        type: "movie",
        title: "Godfather",
        year: 1972,
        monitored: true
      })

      # Sequel torrent
      torrent_info = %{
        type: :movie,
        title: "Godfather II",
        year: 1974,
        quality: "1080p"
      }

      # Should not match due to sequel marker mismatch
      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "detects numbered sequel markers" do
      insert(:media_item, %{
        type: "movie",
        title: "Iron Man",
        year: 2008,
        monitored: true
      })

      torrent_info = %{
        type: :movie,
        title: "Iron Man 2",
        year: 2010,
        quality: "1080p"
      }

      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "detects 'Part' sequel markers" do
      insert(:media_item, %{
        type: "movie",
        title: "Harry Potter and the Deathly Hallows",
        year: 2010,
        monitored: true
      })

      torrent_info = %{
        type: :movie,
        title: "Harry Potter and the Deathly Hallows Part 2",
        year: 2011,
        quality: "1080p"
      }

      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "detects common sequel word markers (Reloaded, Returns, etc.)" do
      insert(:media_item, %{
        type: "movie",
        title: "The Matrix",
        year: 1999,
        monitored: true
      })

      torrent_info = %{
        type: :movie,
        title: "The Matrix Reloaded",
        year: 2003,
        quality: "1080p"
      }

      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "matches movies when both have sequel markers" do
      # If both have sequel markers, they might be the same movie
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Star Wars Episode V",
          year: 1980,
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Star Wars Episode V The Empire Strikes Back",
        year: 1980,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
    end
  end

  describe "word boundary checking" do
    test "prevents 'Alien' matching 'Aliens'" do
      # Aliens (1986)
      insert(:media_item, %{
        type: "movie",
        title: "Aliens",
        year: 1986,
        monitored: true
      })

      # Alien torrent
      torrent_info = %{
        type: :movie,
        title: "Alien",
        year: 1986,
        quality: "1080p"
      }

      # Should not match due to word boundary check (singular vs plural)
      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "prevents 'Alien' library matching 'Aliens' torrent" do
      # Alien (1979)
      insert(:media_item, %{
        type: "movie",
        title: "Alien",
        year: 1979,
        monitored: true
      })

      # Aliens torrent
      torrent_info = %{
        type: :movie,
        title: "Aliens",
        year: 1979,
        quality: "1080p"
      }

      assert {:error, :no_match_found} = TorrentMatcher.find_match(torrent_info)
    end

    test "allows exact singular/plural matches with correct years" do
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Aliens",
          year: 1986,
          monitored: true
        })

      torrent_info = %{
        type: :movie,
        title: "Aliens",
        year: 1986,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
    end
  end

  describe "combined enhancements integration" do
    test "comprehensive test: Matrix example" do
      # The Matrix (1999)
      matrix =
        insert(:media_item, %{
          type: "movie",
          title: "The Matrix",
          year: 1999,
          monitored: true
        })

      # Matrix Reloaded (2003)
      insert(:media_item, %{
        type: "movie",
        title: "The Matrix Reloaded",
        year: 2003,
        monitored: true
      })

      # Searching for The Matrix should only match the first one
      torrent_info = %{
        type: :movie,
        title: "The Matrix",
        year: 1999,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == matrix.id
      assert match.confidence > 0.8
    end

    test "comprehensive test: Alien series" do
      # Alien (1979)
      alien =
        insert(:media_item, %{
          type: "movie",
          title: "Alien",
          year: 1979,
          monitored: true
        })

      # Aliens (1986)
      insert(:media_item, %{
        type: "movie",
        title: "Aliens",
        year: 1986,
        monitored: true
      })

      # Alien 3 (1992)
      insert(:media_item, %{
        type: "movie",
        title: "Alien 3",
        year: 1992,
        monitored: true
      })

      # Searching for Alien (1979) should only match the first one
      torrent_info = %{
        type: :movie,
        title: "Alien",
        year: 1979,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == alien.id
    end

    test "handles legitimate title variations" do
      # Movie with subtitle
      movie =
        insert(:media_item, %{
          type: "movie",
          title: "Dr. Strangelove",
          year: 1964,
          monitored: true
        })

      # Torrent has full title
      torrent_info = %{
        type: :movie,
        title: "Dr. Strangelove or: How I Learned to Stop Worrying and Love the Bomb",
        year: 1964,
        quality: "1080p"
      }

      assert {:ok, match} = TorrentMatcher.find_match(torrent_info)
      assert match.media_item.id == movie.id
      # Confidence might be lower but should still match
      assert match.confidence > 0.6
    end
  end
end
