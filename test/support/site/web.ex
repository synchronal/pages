defmodule Test.Site.Web do
  def live_view(opts) do
    quote do
      use Phoenix.LiveView, unquote(opts)
      import Moar.Sugar
    end
  end

  defmacro __using__(type, opts \\ []) when type in ~w[live_view]a do
    apply(__MODULE__, type, [opts])
  end
end
