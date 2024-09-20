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

  def mount(%{"case" => "handle-params"}, _session, socket),
    do: socket |> ok()

  @impl Phoenix.LiveView
  def handle_params(%{"case" => "handle-params", "do" => "initial-live"}, _url, socket),
    do: socket |> redirect(to: "/live") |> noreply()

  def handle_params(%{"case" => "handle-params", "do" => "connected-live"}, _url, socket) do
    if connected?(socket) do
      socket
      |> redirect(to: "/live")
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def handle_params(%{"case" => "handle-params", "do" => "initial-dead"}, _url, socket),
    do: socket |> redirect(to: "/pages/show") |> noreply()

  def handle_params(%{"case" => "handle-params", "do" => "connected-dead"}, _url, socket) do
    if connected?(socket) do
      socket
      |> redirect(to: "/pages/show")
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def handle_params(%{"case" => "manual"}, _session, socket), do: socket |> noreply()
  def handle_params(%{"case" => "initial-live"}, _session, socket), do: socket |> noreply()
  def handle_params(%{"case" => "connected-live"}, _session, socket), do: socket |> noreply()
  def handle_params(%{"case" => "initial-dead"}, _session, socket), do: socket |> noreply()
  def handle_params(%{"case" => "connected-dead"}, _session, socket), do: socket |> noreply()

  @impl Phoenix.LiveView
  def handle_event("trigger-async-redirect", _params, socket) do
    send(self(), :async_redirect)
    socket |> noreply()
  end

  @impl Phoenix.LiveView
  def handle_info(:async_redirect, socket),
    do: socket |> redirect(to: "/pages/show") |> noreply()
end
