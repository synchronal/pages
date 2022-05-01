defmodule Pages.ShimTest do
  # @related [subject](/lib/pages/shim.ex)

  use Test.SimpleCase

  describe "__endpoint" do
    test "is the configured module" do
      Gestalt.replace_config(:pages, :phoenix_endpoint, Web.SomeEndpoint, self())

      Pages.Shim.__endpoint()
      |> assert_eq(Web.SomeEndpoint)
    end

    test "raises if endpoint is not configured" do
      assert_raise RuntimeError, fn ->
        Pages.Shim.__endpoint()
      end
    end
  end
end
