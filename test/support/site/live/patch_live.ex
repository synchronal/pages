defmodule Test.Site.PatchLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id={"live/patch/#{@case}"}>
      Live view content
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"case" => case}, _session, socket), do: socket |> assign(case: case) |> ok()

  @impl Phoenix.LiveView
  def handle_params(%{"case" => "render"}, _url, socket), do: socket |> noreply()

  def handle_params(%{"do" => "initial-live", "replace" => "true"}, _url, socket),
    do: socket |> push_patch(to: "/live/patch/render", replace: true) |> noreply()

  def handle_params(%{"do" => "initial-live"}, _url, socket),
    do: socket |> push_patch(to: "/live/patch/render") |> noreply()

  def handle_params(%{"do" => "connected-live", "replace" => "true"}, _url, socket) do
    if connected?(socket) do
      socket
      |> push_patch(to: "/live/patch/render", replace: true)
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def handle_params(%{"do" => "connected-live"}, _url, socket) do
    if connected?(socket) do
      socket
      |> push_patch(to: "/live/patch/render")
      |> tap(fn _ -> IO.puts("here") end)
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def handle_params(%{"do" => "initial-dead", "replace" => "true"}, _url, socket),
    do: socket |> push_patch(to: "/pages/show", replace: true) |> noreply()

  def handle_params(%{"do" => "initial-dead"}, _url, socket),
    do: socket |> push_patch(to: "/pages/show") |> noreply()

  def handle_params(%{"do" => "connected-dead", "replace" => "true"}, _url, socket) do
    if connected?(socket) do
      socket
      |> push_patch(to: "/pages/show", replace: true)
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

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
