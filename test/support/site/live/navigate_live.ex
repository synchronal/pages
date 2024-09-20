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

  def mount(%{"case" => "initial-dead"}, _session, socket) do
    socket
    |> push_navigate(to: "/pages/show")
    |> ok()
  end

  def mount(%{"case" => "connected-dead"}, _session, socket) do
    if connected?(socket) do
      socket
      |> push_navigate(to: "/pages/show")
      |> ok()
    else
      socket
      |> ok()
    end
  end

  def mount(%{"case" => "handle-params"}, _session, socket),
    do: socket |> ok()

  @impl Phoenix.LiveView
  def handle_params(%{"do" => "initial-live"}, _url, socket),
    do: socket |> push_navigate(to: "/live") |> noreply()

  def handle_params(%{"do" => "connected-live"}, _url, socket) do
    if connected?(socket) do
      socket
      |> push_navigate(to: "/live")
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def handle_params(%{"do" => "initial-dead"}, _url, socket),
    do: socket |> push_navigate(to: "/pages/show") |> noreply()

  def handle_params(%{"do" => "connected-dead"}, _url, socket) do
    if connected?(socket) do
      socket
      |> push_navigate(to: "/pages/show")
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def handle_params(%{"case" => "initial-live"}, _url, socket), do: socket |> noreply()
  def handle_params(%{"case" => "connected-live"}, _url, socket), do: socket |> noreply()
  def handle_params(%{"case" => "initial-dead"}, _url, socket), do: socket |> noreply()
  def handle_params(%{"case" => "connected-dead"}, _url, socket), do: socket |> noreply()
end
