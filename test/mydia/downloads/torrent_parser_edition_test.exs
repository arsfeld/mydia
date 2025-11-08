defmodule Mydia.Downloads.TorrentParserEditionTest do
  use ExUnit.Case, async: true

  alias Mydia.Downloads.TorrentParser

  describe "edition detection" do
    test "detects Director's Cut" do
      assert {:ok, info} =
               TorrentParser.parse("Blade.Runner.1982.Directors.Cut.1080p.BluRay.x264-GROUP")

      assert info.type == :movie
      assert info.title == "Blade Runner"
      assert info.year == 1982
      assert info.edition == "Director's Cut"
    end

    test "detects Director's Cut with apostrophe" do
      assert {:ok, info} =
               TorrentParser.parse("Apocalypse.Now.1979.Director's.Cut.1080p.BluRay.x264-GROUP")

      assert info.edition == "Director's Cut"
    end

    test "detects Director's Edition" do
      assert {:ok, info} =
               TorrentParser.parse(
                 "Kingdom.of.Heaven.2005.Directors.Edition.1080p.BluRay.x264-GROUP"
               )

      assert info.edition == "Director's Cut"
    end

    test "detects Extended Edition" do
      assert {:ok, info} =
               TorrentParser.parse(
                 "The.Lord.of.the.Rings.2001.Extended.Edition.1080p.BluRay.x264-GROUP"
               )

      assert info.type == :movie
      assert info.title == "The Lord of the Rings"
      assert info.year == 2001
      assert info.edition == "Extended Edition"
    end

    test "detects Extended Cut" do
      assert {:ok, info} =
               TorrentParser.parse("Watchmen.2009.Extended.Cut.1080p.BluRay.x264-GROUP")

      assert info.edition == "Extended Edition"
    end

    test "detects Extended Version" do
      assert {:ok, info} =
               TorrentParser.parse("Aliens.1986.Extended.Version.1080p.BluRay.x264-GROUP")

      assert info.edition == "Extended Edition"
    end

    test "detects Theatrical Release" do
      assert {:ok, info} =
               TorrentParser.parse(
                 "Blade.Runner.1982.Theatrical.Release.1080p.BluRay.x264-GROUP"
               )

      assert info.edition == "Theatrical"
    end

    test "detects Theatrical Cut" do
      assert {:ok, info} =
               TorrentParser.parse("The.Abyss.1989.Theatrical.Cut.1080p.BluRay.x264-GROUP")

      assert info.edition == "Theatrical"
    end

    test "detects Theatrical Edition" do
      assert {:ok, info} =
               TorrentParser.parse(
                 "Kingdom.of.Heaven.2005.Theatrical.Edition.1080p.BluRay.x264-GROUP"
               )

      assert info.edition == "Theatrical"
    end

    test "detects Ultimate Edition" do
      assert {:ok, info} =
               TorrentParser.parse("Superman.1978.Ultimate.Edition.1080p.BluRay.x264-GROUP")

      assert info.edition == "Ultimate Edition"
    end

    test "detects Ultimate Cut" do
      assert {:ok, info} =
               TorrentParser.parse("Watchmen.2009.Ultimate.Cut.1080p.BluRay.x264-GROUP")

      assert info.edition == "Ultimate Edition"
    end

    test "detects Collector's Edition" do
      assert {:ok, info} =
               TorrentParser.parse("Alien.1979.Collectors.Edition.1080p.BluRay.x264-GROUP")

      assert info.edition == "Collector's Edition"
    end

    test "detects Collector's Edition with apostrophe" do
      assert {:ok, info} =
               TorrentParser.parse("Predator.1987.Collector's.Edition.1080p.BluRay.x264-GROUP")

      assert info.edition == "Collector's Edition"
    end

    test "detects Special Edition" do
      assert {:ok, info} =
               TorrentParser.parse("Star.Wars.1977.Special.Edition.1080p.BluRay.x264-GROUP")

      assert info.edition == "Special Edition"
    end

    test "detects Unrated" do
      assert {:ok, info} =
               TorrentParser.parse("The.Hangover.2009.Unrated.1080p.BluRay.x264-GROUP")

      assert info.edition == "Unrated"
    end

    test "detects Remastered" do
      assert {:ok, info} =
               TorrentParser.parse("Star.Trek.1979.Remastered.1080p.BluRay.x264-GROUP")

      assert info.edition == "Remastered"
    end

    test "detects IMAX" do
      assert {:ok, info} =
               TorrentParser.parse("The.Dark.Knight.2008.IMAX.1080p.BluRay.x264-GROUP")

      assert info.edition == "IMAX"
    end

    test "returns nil when no edition is present" do
      assert {:ok, info} = TorrentParser.parse("The.Matrix.1999.1080p.BluRay.x264-GROUP")

      assert info.type == :movie
      assert info.title == "The Matrix"
      assert info.year == 1999
      assert info.edition == nil
    end

    test "detects edition with different spacing" do
      assert {:ok, info} =
               TorrentParser.parse("Blade.Runner.1982.DirectorsCut.1080p.BluRay.x264-GROUP")

      assert info.edition == "Director's Cut"
    end

    test "detects edition case-insensitively" do
      assert {:ok, info} =
               TorrentParser.parse("Aliens.1986.EXTENDED.EDITION.1080p.BluRay.x264-GROUP")

      assert info.edition == "Extended Edition"
    end

    test "edition detection doesn't break other metadata extraction" do
      assert {:ok, info} =
               TorrentParser.parse(
                 "The.Lord.of.the.Rings.2001.Extended.Edition.2160p.BluRay.x265-SPARKS"
               )

      assert info.type == :movie
      assert info.title == "The Lord of the Rings"
      assert info.year == 2001
      assert info.quality == "2160p"
      assert info.source == "BluRay"
      assert info.codec == "x265"
      assert info.release_group == "SPARKS"
      assert info.edition == "Extended Edition"
    end

    test "handles multiple edition keywords by taking first match" do
      # Director's Cut should match before Extended because it appears first in the cond
      assert {:ok, info} =
               TorrentParser.parse(
                 "Movie.2020.Directors.Cut.Extended.Edition.1080p.BluRay.x264-GROUP"
               )

      # Should match Director's Cut since it's checked first in the cond
      assert info.edition == "Director's Cut"
    end

    test "edition detection works with complex titles" do
      assert {:ok, info} =
               TorrentParser.parse(
                 "The.Lord.of.the.Rings.The.Fellowship.of.the.Ring.2001.Extended.Edition.1080p.BluRay.x264-GROUP"
               )

      assert info.title == "The Lord of the Rings The Fellowship of the Ring"
      assert info.year == 2001
      assert info.edition == "Extended Edition"
    end

    test "TV shows don't have edition field" do
      assert {:ok, info} =
               TorrentParser.parse(
                 "Breaking.Bad.S01E01.Extended.Edition.720p.HDTV.x264-CTU"
               )

      assert info.type == :tv
      # Edition is only extracted for movies, not TV shows
      refute Map.has_key?(info, :edition)
    end
  end
end
