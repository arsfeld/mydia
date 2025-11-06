defmodule Mydia.Downloads.TorrentParserTest do
  use ExUnit.Case, async: true
  alias Mydia.Downloads.TorrentParser

  describe "parse/1 - movies" do
    test "parses standard movie torrent name with dots" do
      {:ok, info} = TorrentParser.parse("The.Matrix.1999.1080p.BluRay.x264-SPARKS")

      assert info.type == :movie
      assert info.title == "The Matrix"
      assert info.year == 1999
      assert info.quality == "1080p"
      assert info.source == "BluRay"
      assert info.codec == "x264"
      assert info.release_group == "SPARKS"
    end

    test "parses movie with spaces and brackets" do
      {:ok, info} = TorrentParser.parse("Inception (2010) 720p BluRay x264-YIFY")

      assert info.type == :movie
      assert info.title == "Inception"
      assert info.year == 2010
      assert info.quality == "720p"
      assert info.source == "BluRay"
      assert info.codec == "x264"
      assert info.release_group == "YIFY"
    end

    test "parses movie with WEB-DL source" do
      {:ok, info} = TorrentParser.parse("Dune.2021.2160p.WEB-DL.x265-EVO")

      assert info.type == :movie
      assert info.title == "Dune"
      assert info.year == 2021
      assert info.quality == "2160p"
      assert info.source == "WEB-DL"
      assert info.codec == "x265"
      assert info.release_group == "EVO"
    end

    test "parses movie with multiple words in title" do
      {:ok, info} = TorrentParser.parse("The.Lord.of.the.Rings.2001.1080p.BluRay.x264-GROUP")

      assert info.type == :movie
      assert info.title == "The Lord of the Rings"
      assert info.year == 2001
    end

    test "handles movie without release group" do
      {:ok, info} = TorrentParser.parse("Interstellar.2014.1080p.BluRay.x264")

      assert info.type == :movie
      assert info.title == "Interstellar"
      assert info.year == 2014
      assert info.release_group == nil
    end
  end

  describe "parse/1 - TV shows" do
    test "parses standard TV show with S01E01 format" do
      {:ok, info} = TorrentParser.parse("Breaking.Bad.S01E01.720p.HDTV.x264-CTU")

      assert info.type == :tv
      assert info.title == "Breaking Bad"
      assert info.season == 1
      assert info.episode == 1
      assert info.quality == "720p"
      assert info.source == "HDTV"
      assert info.codec == "x264"
      assert info.release_group == "CTU"
    end

    test "parses TV show with single digit season and episode" do
      {:ok, info} = TorrentParser.parse("Friends.S1E5.1080p.WEB-DL.x264-NTb")

      assert info.type == :tv
      assert info.title == "Friends"
      assert info.season == 1
      assert info.episode == 5
    end

    test "parses TV show with 1x01 format" do
      {:ok, info} = TorrentParser.parse("Game.of.Thrones.1x01.720p.HDTV.x264-CTU")

      assert info.type == :tv
      assert info.title == "Game of Thrones"
      assert info.season == 1
      assert info.episode == 1
    end

    test "parses TV show with multiple words in title" do
      {:ok, info} = TorrentParser.parse("The.Big.Bang.Theory.S10E15.1080p.WEB-DL.x264-RBB")

      assert info.type == :tv
      assert info.title == "The Big Bang Theory"
      assert info.season == 10
      assert info.episode == 15
    end

    test "handles TV show without release group" do
      {:ok, info} = TorrentParser.parse("Stranger.Things.S02E03.1080p.WEBRip.x265")

      assert info.type == :tv
      assert info.title == "Stranger Things"
      assert info.season == 2
      assert info.episode == 3
      assert info.release_group == nil
    end
  end

  describe "parse/1 - edge cases" do
    test "handles file extension in name" do
      {:ok, info} = TorrentParser.parse("The.Matrix.1999.1080p.BluRay.x264.mkv")

      assert info.type == :movie
      assert info.title == "The Matrix"
    end

    test "returns error for unparseable name" do
      assert {:error, :unable_to_parse} = TorrentParser.parse("random-file-name")
    end

    test "returns error for empty string" do
      assert {:error, :unable_to_parse} = TorrentParser.parse("")
    end
  end

  describe "parse/1 - quality detection" do
    test "detects 4K quality" do
      {:ok, info} = TorrentParser.parse("Movie.2020.4K.UHD.BluRay.x265-GRP")
      assert info.quality == "2160p"
    end

    test "detects 2160p quality" do
      {:ok, info} = TorrentParser.parse("Movie.2020.2160p.WEB-DL.x265-GRP")
      assert info.quality == "2160p"
    end

    test "detects SD quality" do
      {:ok, info} = TorrentParser.parse("Movie.2020.SD.DVDRip.x264-GRP")
      assert info.quality == "SD"
    end
  end

  describe "parse/1 - source detection" do
    test "detects various BluRay formats" do
      {:ok, info1} = TorrentParser.parse("Movie.2020.1080p.BluRay.x264-GRP")
      {:ok, info2} = TorrentParser.parse("Movie.2020.1080p.Blu-Ray.x264-GRP")
      {:ok, info3} = TorrentParser.parse("Movie.2020.1080p.BDRip.x264-GRP")
      {:ok, info4} = TorrentParser.parse("Movie.2020.1080p.BRRip.x264-GRP")

      assert info1.source == "BluRay"
      assert info2.source == "BluRay"
      assert info3.source == "BluRay"
      assert info4.source == "BluRay"
    end

    test "distinguishes between WEB-DL and WEBRip" do
      {:ok, info1} = TorrentParser.parse("Movie.2020.1080p.WEB-DL.x264-GRP")
      {:ok, info2} = TorrentParser.parse("Movie.2020.1080p.WEBRip.x264-GRP")

      assert info1.source == "WEB-DL"
      assert info2.source == "WEBRip"
    end
  end

  describe "parse/1 - codec detection" do
    test "detects x265/HEVC codecs" do
      {:ok, info1} = TorrentParser.parse("Movie.2020.1080p.BluRay.x265-GRP")
      {:ok, info2} = TorrentParser.parse("Movie.2020.1080p.BluRay.h265-GRP")
      {:ok, info3} = TorrentParser.parse("Movie.2020.1080p.BluRay.HEVC-GRP")

      assert info1.codec == "x265"
      assert info2.codec == "x265"
      assert info3.codec == "x265"
    end

    test "detects x264 codec" do
      {:ok, info} = TorrentParser.parse("Movie.2020.1080p.BluRay.x264-GRP")
      assert info.codec == "x264"
    end
  end

  describe "parse/1 - season packs" do
    test "parses season pack with COMPLETE marker" do
      {:ok, info} =
        TorrentParser.parse("House.of.the.Dragon.S01.COMPLETE.2160p.BluRay.x265-GROUP")

      assert info.type == :tv_season
      assert info.title == "House of the Dragon"
      assert info.season == 1
      assert info.season_pack == true
      assert info.quality == "2160p"
      assert info.source == "BluRay"
      assert info.codec == "x265"
    end

    test "parses season pack without COMPLETE marker" do
      {:ok, info} = TorrentParser.parse("Yellowstone.S04.1080p.BluRay.x264-MIXED")

      assert info.type == :tv_season
      assert info.title == "Yellowstone"
      assert info.season == 4
      assert info.season_pack == true
      assert info.quality == "1080p"
    end

    test "parses season pack with single digit season" do
      {:ok, info} = TorrentParser.parse("Naruto.S2.720p.WEB-DL.x264-GRP")

      assert info.type == :tv_season
      assert info.title == "Naruto"
      assert info.season == 2
      assert info.season_pack == true
    end

    test "parses season pack with multiple quality info" do
      {:ok, info} = TorrentParser.parse("The.Last.of.Us.S02.1080p.WEB-DL.DDP5.1.x265-GROUP")

      assert info.type == :tv_season
      assert info.title == "The Last of Us"
      assert info.season == 2
      assert info.quality == "1080p"
      assert info.source == "WEB-DL"
      assert info.codec == "x265"
    end
  end

  describe "parse/1 - prefix stripping" do
    test "strips Chinese bracket prefixes and season markers" do
      {:ok, info} =
        TorrentParser.parse("【高清剧集网 www.BTHDTV.com】猎魔人 第二季.The.Witcher.S02E01.1080p.WEB-DL.x265")

      assert info.type == :tv
      # Chinese season marker "第二季" should be removed
      assert info.title == "猎魔人 The Witcher"
      assert info.season == 2
      assert info.episode == 1
    end

    test "strips website tracker tags" do
      {:ok, info} = TorrentParser.parse("[47BT]Yellowstone.S02.1080p.BluRay.x264-MIXED")

      assert info.type == :tv_season
      assert info.title == "Yellowstone"
      assert info.season == 2
    end

    test "strips tracker domain tags" do
      {:ok, info} = TorrentParser.parse("[Ex-torrenty.org]The.Last.of.Us.S02.1080p.WEB-DL.x265")

      assert info.type == :tv_season
      assert info.title == "The Last of Us"
      assert info.season == 2
    end

    test "strips multiple bracket types" do
      {:ok, info} = TorrentParser.parse("[Tracker]Severance.S02.MULTi.1080p.WEB-DL.x264-GRP")

      assert info.type == :tv_season
      assert info.title == "Severance"
      assert info.season == 2
    end

    test "handles complex Chinese torrent with multiple brackets" do
      {:ok, info} =
        TorrentParser.parse(
          "[bitsearch.to] 【高清剧集网 www.BTHDTV.com】怪奇物语 第四季[全9集][简繁英字幕].Stranger.Things.S04.2022.NF.WEB-DL.2160p.HEVC.HDR.DDP-Xiaomi"
        )

      assert info.type == :tv_season
      # All brackets and Chinese season markers should be removed
      assert info.title == "怪奇物语 Stranger Things"
      assert info.season == 4
    end

    test "handles Chinese torrent with numbered season marker" do
      {:ok, info} =
        TorrentParser.parse("47BT.老友记.第6季.Friends.S06.1999.BluRay.2160p.10Bit.DV.HDR.HEVC.DDP5.1")

      assert info.type == :tv_season
      # "第6季" should be removed, leaving Chinese and English titles
      assert info.title == "47BT 老友记 Friends"
      assert info.season == 6
    end

    test "handles multiple leading brackets and Chinese content" do
      {:ok, info} =
        TorrentParser.parse(
          "[bitsearch.to] 【高清剧集网发布 www.DDHDTV.com】黄石 第一季[全9集][中文字幕].Yellowstone.S01.2018.2160p.NF.WEB-DL.DDP5.1.H.265-LelveTV"
        )

      assert info.type == :tv_season
      assert info.title == "黄石 Yellowstone"
      assert info.season == 1
    end
  end

  describe "parse/1 - multiple language codes" do
    test "handles multiple language codes in title" do
      {:ok, info} = TorrentParser.parse("Naruto.S04.ITA.JPN.1080p.WEB-DL.x264-GRP")

      assert info.type == :tv_season
      assert info.title == "Naruto"
      assert info.season == 4
      assert info.quality == "1080p"
    end

    test "handles MULTi language marker" do
      {:ok, info} = TorrentParser.parse("Severance.S02.MULTi.1080p.WEB-DL.x264-GRP")

      assert info.type == :tv_season
      assert info.title == "Severance"
      assert info.season == 2
    end

    test "handles DUAL language marker" do
      {:ok, info} = TorrentParser.parse("Breaking.Bad.S05E01.DUAL.1080p.BluRay.x264-GRP")

      assert info.type == :tv
      assert info.title == "Breaking Bad"
      assert info.season == 5
      assert info.episode == 1
    end
  end

  describe "parse/1 - non-standard formats" do
    test "handles reencode marker" do
      {:ok, info} = TorrentParser.parse("Rebuild of Naruto S02 - Rvby1 Reencode.mkv")

      assert info.type == :tv_season
      assert info.title == "Rebuild of Naruto"
      assert info.season == 2
    end

    test "handles series with periods in name" do
      {:ok, info} = TorrentParser.parse("Mysteria.Friends.S01.1080p.WEB-DL.x264")

      assert info.type == :tv_season
      assert info.title == "Mysteria Friends"
      assert info.season == 1
    end
  end
end
