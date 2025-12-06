defmodule Mydia.Library.GeneratedMediaTest do
  use ExUnit.Case, async: true

  alias Mydia.Library.GeneratedMedia

  @test_content "test binary content for generated media"

  setup do
    # Use a temporary directory for tests
    test_dir = Path.join([System.tmp_dir!(), "generated_media_test_#{:rand.uniform(100_000)}"])
    File.mkdir_p!(test_dir)

    # Configure the test directory
    Application.put_env(:mydia, :generated_media_path, test_dir)

    on_exit(fn ->
      File.rm_rf!(test_dir)
      Application.delete_env(:mydia, :generated_media_path)
    end)

    {:ok, test_dir: test_dir}
  end

  describe "store/2" do
    test "stores content and returns checksum for cover type", %{test_dir: test_dir} do
      assert {:ok, checksum} = GeneratedMedia.store(:cover, @test_content)

      # Verify checksum format (32 character hex string)
      assert String.length(checksum) == 32
      assert Regex.match?(~r/^[0-9a-f]+$/, checksum)

      # Verify file exists
      expected_path =
        Path.join([
          test_dir,
          "covers",
          String.slice(checksum, 0, 2),
          String.slice(checksum, 2, 2),
          "#{checksum}.jpg"
        ])

      assert File.exists?(expected_path)
      assert File.read!(expected_path) == @test_content
    end

    test "stores content for all supported types" do
      for type <- [:cover, :sprite, :vtt, :preview] do
        assert {:ok, checksum} = GeneratedMedia.store(type, "content for #{type}")
        assert GeneratedMedia.exists?(type, checksum)
      end
    end

    test "returns consistent checksum for same content" do
      {:ok, checksum1} = GeneratedMedia.store(:cover, @test_content)
      {:ok, checksum2} = GeneratedMedia.store(:cover, @test_content)

      assert checksum1 == checksum2
    end

    test "returns different checksum for different content" do
      {:ok, checksum1} = GeneratedMedia.store(:cover, "content 1")
      {:ok, checksum2} = GeneratedMedia.store(:cover, "content 2")

      refute checksum1 == checksum2
    end
  end

  describe "store_file/2" do
    test "stores file from disk and returns checksum", %{test_dir: test_dir} do
      # Create a temporary source file
      source_path = Path.join(test_dir, "source.bin")
      File.write!(source_path, @test_content)

      assert {:ok, checksum} = GeneratedMedia.store_file(:cover, source_path)
      assert GeneratedMedia.exists?(:cover, checksum)

      # Verify content matches
      stored_content = GeneratedMedia.get_path(:cover, checksum) |> File.read!()
      assert stored_content == @test_content
    end

    test "returns error for non-existent file" do
      assert {:error, :enoent} = GeneratedMedia.store_file(:cover, "/nonexistent/file.bin")
    end
  end

  describe "get_path/2" do
    test "returns correct path structure", %{test_dir: test_dir} do
      checksum = "abc123def456789012345678901234ab"

      path = GeneratedMedia.get_path(:cover, checksum)

      assert path == Path.join([test_dir, "covers", "ab", "c1", "#{checksum}.jpg"])
    end

    test "uses correct extension for each type" do
      checksum = "abc123def456789012345678901234ab"

      assert GeneratedMedia.get_path(:cover, checksum) =~ ".jpg"
      assert GeneratedMedia.get_path(:sprite, checksum) =~ ".jpg"
      assert GeneratedMedia.get_path(:vtt, checksum) =~ ".vtt"
      assert GeneratedMedia.get_path(:preview, checksum) =~ ".mp4"
    end

    test "uses correct directory for each type" do
      checksum = "abc123def456789012345678901234ab"

      assert GeneratedMedia.get_path(:cover, checksum) =~ "/covers/"
      assert GeneratedMedia.get_path(:sprite, checksum) =~ "/sprites/"
      assert GeneratedMedia.get_path(:vtt, checksum) =~ "/vtt/"
      assert GeneratedMedia.get_path(:preview, checksum) =~ "/previews/"
    end
  end

  describe "exists?/2" do
    test "returns true for existing file" do
      {:ok, checksum} = GeneratedMedia.store(:cover, @test_content)
      assert GeneratedMedia.exists?(:cover, checksum)
    end

    test "returns false for non-existing file" do
      refute GeneratedMedia.exists?(:cover, "nonexistent123456789012345678901")
    end

    test "returns false for wrong type with existing checksum" do
      {:ok, checksum} = GeneratedMedia.store(:cover, @test_content)
      refute GeneratedMedia.exists?(:sprite, checksum)
    end
  end

  describe "delete/2" do
    test "deletes existing file" do
      {:ok, checksum} = GeneratedMedia.store(:cover, @test_content)
      assert GeneratedMedia.exists?(:cover, checksum)

      assert :ok = GeneratedMedia.delete(:cover, checksum)
      refute GeneratedMedia.exists?(:cover, checksum)
    end

    test "returns :ok for non-existent file" do
      assert :ok = GeneratedMedia.delete(:cover, "nonexistent123456789012345678901")
    end
  end

  describe "url_path/2" do
    test "returns correct URL path" do
      checksum = "abc123def456789012345678901234ab"

      url = GeneratedMedia.url_path(:cover, checksum)

      assert url == "/generated/covers/ab/c1/#{checksum}.jpg"
    end

    test "uses correct extension for each type" do
      checksum = "abc123def456789012345678901234ab"

      assert GeneratedMedia.url_path(:cover, checksum) =~ ".jpg"
      assert GeneratedMedia.url_path(:sprite, checksum) =~ ".jpg"
      assert GeneratedMedia.url_path(:vtt, checksum) =~ ".vtt"
      assert GeneratedMedia.url_path(:preview, checksum) =~ ".mp4"
    end
  end

  describe "base_path/0" do
    test "returns configured path when set", %{test_dir: test_dir} do
      assert GeneratedMedia.base_path() == test_dir
    end

    test "returns default path when not configured" do
      Application.delete_env(:mydia, :generated_media_path)

      # In test env, should fall back to priv/generated
      path = GeneratedMedia.base_path()
      assert path =~ "priv/generated"
    end
  end
end
