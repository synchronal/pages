defmodule Test.Site.PageLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id="live">
      Live view content
    </main>
    """
  end
end
