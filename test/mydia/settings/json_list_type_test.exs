defmodule Mydia.Settings.JsonListTypeTest do
  use ExUnit.Case, async: true

  alias Mydia.Settings.JsonListType

  describe "load/1" do
    test "loads valid JSON array" do
      json = ~s([{"name":"test","value":"123"}])
      assert {:ok, [%{"name" => "test", "value" => "123"}]} = JsonListType.load(json)
    end

    test "loads empty array" do
      assert {:ok, []} = JsonListType.load("[]")
    end

    test "handles nil" do
      assert {:ok, []} = JsonListType.load(nil)
    end

    test "handles empty string" do
      assert {:ok, []} = JsonListType.load("")
    end

    test "handles old wrapped format for backwards compatibility" do
      # Old cookie format: {"cookies": [...]}
      json = ~s({"cookies":[{"name":"test","value":"123"}]})
      assert {:ok, [%{"name" => "test", "value" => "123"}]} = JsonListType.load(json)
    end

    test "handles old format (other maps) for backwards compatibility" do
      # Unknown old format was stored as a map
      json = ~s({"key":"value"})
      assert {:ok, []} = JsonListType.load(json)
    end

    test "handles empty object for backwards compatibility" do
      assert {:ok, []} = JsonListType.load("{}")
    end

    test "handles already-decoded list" do
      assert {:ok, [1, 2, 3]} = JsonListType.load([1, 2, 3])
    end

    test "handles already-decoded map for backwards compatibility" do
      assert {:ok, []} = JsonListType.load(%{"key" => "value"})
    end

    test "returns error for invalid JSON" do
      assert {:error, "Invalid JSON"} = JsonListType.load("{invalid json")
    end
  end

  describe "dump/1" do
    test "dumps list to JSON" do
      list = [%{"name" => "test"}]
      assert {:ok, json} = JsonListType.dump(list)
      assert json == ~s([{"name":"test"}])
    end

    test "dumps empty list" do
      assert {:ok, "[]"} = JsonListType.dump([])
    end

    test "handles nil" do
      assert {:ok, "[]"} = JsonListType.dump(nil)
    end
  end

  describe "cast/1" do
    test "casts list" do
      assert {:ok, [1, 2, 3]} = JsonListType.cast([1, 2, 3])
    end

    test "casts nil to empty list" do
      assert {:ok, []} = JsonListType.cast(nil)
    end

    test "rejects non-list values" do
      assert :error = JsonListType.cast("string")
      assert :error = JsonListType.cast(%{})
      assert :error = JsonListType.cast(123)
    end
  end
end
