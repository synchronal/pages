defmodule Test.Site.RedirectLive do
  @moduledoc false
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
    |> redirect(to: "/live")
    |> ok()
  end

  def mount(%{"case" => "connected-live"}, _session, socket) do
    if connected?(socket) do
      socket
      |> redirect(to: "/live")
      |> ok()
    else
      socket
      |> ok()
    end
  end

  def mount(%{"case" => "initial-dead"}, _session, socket) do
    socket
    |> redirect(to: "/pages/show")
    |> ok()
  end

  def mount(%{"case" => "connected-dead"}, _session, socket) do
    if connected?(socket) do
      socket
      |> redirect(to: "/pages/show")
      |> ok()
    else
      socket
      |> ok()
    end
  end
end
