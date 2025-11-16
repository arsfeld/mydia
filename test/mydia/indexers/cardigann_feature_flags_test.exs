defmodule Mydia.Indexers.CardigannFeatureFlagsTest do
  use ExUnit.Case, async: false

  alias Mydia.Indexers.CardigannFeatureFlags

  describe "enabled?/0" do
    test "returns false when cardigann_enabled is not set" do
      original = Application.get_env(:mydia, :features, [])

      try do
        Application.put_env(:mydia, :features, [])
        assert CardigannFeatureFlags.enabled?() == false
      after
        Application.put_env(:mydia, :features, original)
      end
    end

    test "returns false when cardigann_enabled is explicitly false" do
      original = Application.get_env(:mydia, :features, [])

      try do
        Application.put_env(:mydia, :features, cardigann_enabled: false)
        assert CardigannFeatureFlags.enabled?() == false
      after
        Application.put_env(:mydia, :features, original)
      end
    end

    test "returns true when cardigann_enabled is true" do
      original = Application.get_env(:mydia, :features, [])

      try do
        Application.put_env(:mydia, :features, cardigann_enabled: true)
        assert CardigannFeatureFlags.enabled?() == true
      after
        Application.put_env(:mydia, :features, original)
      end
    end
  end
end
