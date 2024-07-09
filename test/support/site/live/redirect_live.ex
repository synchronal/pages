defmodule Test.Site.RedirectLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id="live/redirect">
      <button test-role="trigger-async-redirect" phx-click="trigger-async-redirect">trigger later redirect</button>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"case" => "manual"}, _session, socket),
    do: socket |> ok()

  def mount(%{"case" => "initial-live"}, _session, socket),
    do: socket |> redirect(to: "/live") |> ok()

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

  def mount(%{"case" => "initial-dead"}, _session, socket),
    do: socket |> redirect(to: "/pages/show") |> ok()

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

  @impl Phoenix.LiveView
  def handle_event("trigger-async-redirect", _params, socket) do
    send(self(), :async_redirect)
    socket |> noreply()
  end

  @impl Phoenix.LiveView
  def handle_info(:async_redirect, socket),
    do: socket |> redirect(to: "/pages/show") |> noreply()
end
