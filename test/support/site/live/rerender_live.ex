defmodule Test.Site.RerenderLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id="live/rerender">
      <span test-role="content"><%= @content %></span>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    send(self(), :update)

    socket
    |> assign(:content, 0)
    |> ok()
  end

  @impl Phoenix.LiveView
  def handle_info(:update, %{assigns: %{content: content}} = socket),
    do: socket |> assign(content: content + 1) |> noreply()
end
