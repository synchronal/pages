defmodule Test.Site.PageLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(%{live_action: :final} = assigns) do
    ~H"""
    <main test-page-id="live/final">
      Final
    </main>
    """
  end

  def render(assigns) do
    ~H"""
    <main test-page-id="live/show">
      <div test-role="click-count" phx-click="increment-count"><%= @count %></div>
      <button test-role="navigate-button" phx-click="navigate">Click me to navigate</button>
      <button test-role="patch-button" phx-click="patch">Click me to patch</button>
      <button test-role="redirect-dead-button" phx-click="redirect-dead">Click me to redirect to a dead view</button>
      <button test-role="redirect-live-button" phx-click="redirect-live">Click me to redirect to a live view</button>
      <.link test-role="navigate-dead-link" navigate={~p"/pages/show"}>Click me to navigate directly to a dead view</.link>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(:count, 0)
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket),
    do: socket |> noreply()

  @impl Phoenix.LiveView
  def handle_event("increment-count", _params, %{assigns: %{count: count}} = socket),
    do: socket |> assign(count: count + 1) |> noreply()

  def handle_event("navigate", _params, socket),
    do: socket |> push_navigate(to: "/live/final") |> noreply()

  def handle_event("patch", _params, socket),
    do: socket |> push_patch(to: "/live/final") |> noreply()

  def handle_event("redirect-dead", _params, socket),
    do: socket |> redirect(to: "/pages/show") |> noreply()

  def handle_event("redirect-live", _params, socket),
    do: socket |> redirect(to: "/live/final") |> noreply()
end
