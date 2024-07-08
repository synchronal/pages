defmodule Test.Site.PageLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id="live">
      Live view content
    </main>
    """
  end
end
