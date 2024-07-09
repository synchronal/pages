defmodule Test.Site.FormLive do
  use Test.Site.Web, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main test-page-id="live/form">
      <.form :let={f} for={@form} as={:foo} id="form" phx-change="update-form" phx-submit="submit-form">
        <input test-role="action-input" name={f[:action].name} value={f[:action].value} />
        <input test-role="value-input" name={f[:value].name} value={f[:value].value} />
      </.form>

      <.form :let={f} for={@form} as={:foo} id="form-without-phx-attrs">
        <input test-role="value-input" name={f[:value].name} value={f[:value].value} />
      </.form>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket),
    do: socket |> assign(form: to_form(%{})) |> ok()

  @impl Phoenix.LiveView
  def handle_event("submit-form", %{"foo" => %{"value" => "navigate"}}, socket) do
    socket
    |> push_navigate(to: "/live")
    |> noreply()
  end

  def handle_event("submit-form", %{"foo" => %{"value" => "redirect"}}, socket) do
    socket
    |> redirect(to: "/pages/show")
    |> noreply()
  end

  def handle_event("submit-form", %{"foo" => %{"value" => "rerender"}}, socket) do
    socket
    |> assign(form: to_form(%{"value" => "rerendered"}))
    |> noreply()
  end

  def handle_event("update-form", %{"foo" => %{"action" => "navigate"}}, socket) do
    socket
    |> push_navigate(to: "/live")
    |> noreply()
  end

  def handle_event("update-form", %{"foo" => %{"action" => "redirect"}}, socket) do
    socket
    |> redirect(to: "/pages/show")
    |> noreply()
  end

  def handle_event("update-form", %{"foo" => %{"action" => "rerender"} = params}, socket) do
    socket
    |> assign(form: to_form(params))
    |> noreply()
  end
end
