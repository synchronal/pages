defmodule Test.Site.Web do
  def live_view(opts) do
    opts = Keyword.put(opts, :global_prefixes, ~w[test-])

    quote do
      use Phoenix.LiveView, unquote(opts)
      use Phoenix.VerifiedRoutes, endpoint: Test.Site.Endpoint, router: Test.Site.Router
      import Moar.Sugar
    end
  end

  defmacro __using__(type, opts \\ []) when type in ~w[live_view]a do
    apply(__MODULE__, type, [opts])
  end
end
