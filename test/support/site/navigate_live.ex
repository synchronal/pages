defmodule Test.Site.NavigateLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id="live/redirect">
      Live view content
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"case" => "initial-live"}, _session, socket) do
    socket
    |> push_navigate(to: "/live")
    |> ok()
  end

  def mount(%{"case" => "connected-live"}, _session, socket) do
    if connected?(socket) do
      socket
      |> push_navigate(to: "/live")
      |> ok()
    else
      socket
      |> ok()
    end
  end
end
