defmodule Test.Site.PatchLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id="live/patch">
      Live view content
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"case" => "render"}, _session, socket), do: socket |> ok()
  def mount(%{"case" => "handle-params"}, _session, socket), do: socket |> ok()

  @impl Phoenix.LiveView
  def handle_params(%{"case" => "render"}, _url, socket), do: socket |> noreply()

  def handle_params(%{"do" => "initial-live"}, _url, socket),
    do: socket |> push_patch(to: "/live") |> noreply()

  def handle_params(%{"do" => "connected-live"}, _url, socket) do
    if connected?(socket) do
      socket
      |> push_patch(to: "/live/patch?case=render")
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def handle_params(%{"do" => "initial-dead"}, _url, socket),
    do: socket |> push_patch(to: "/pages/show") |> noreply()

  def handle_params(%{"do" => "connected-dead"}, _url, socket) do
    if connected?(socket) do
      socket
      |> push_patch(to: "/pages/show")
      |> noreply()
    else
      socket
      |> noreply()
    end
  end
end
