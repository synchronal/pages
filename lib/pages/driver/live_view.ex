defmodule Pages.Driver.LiveView do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix.LiveView pages.
  """

  @behaviour Pages.Driver

  import Phoenix.LiveViewTest

  alias HtmlQuery, as: Hq

  defstruct ~w[conn live rendered]a

  @type t() :: %__MODULE__{
          conn: Plug.Conn.t(),
          live: any(),
          rendered: binary() | nil
        }

  def new(%Plug.Conn{} = conn),
    do: new(conn, conn.request_path)

  def new(%Plug.Conn{} = conn, request_path) when is_binary(request_path),
    do: new(conn, new_live(conn, request_path))

  def new(%Plug.Conn{} = conn, {:ok, live, rendered}),
    do: __struct__(conn: conn, live: live, rendered: rendered)

  # # #

  @spec click(Pages.Driver.t(), binary(), Hq.Css.selector()) :: Pages.Driver.t()
  def click(%__MODULE__{} = page, title, selector) do
    page.live
    |> element(Hq.Css.selector(selector), title)
    |> render_click()
    |> handle_rendered_result(page)
  end

  @spec rerender(Pages.Driver.t()) :: Pages.Driver.t()
  def rerender(page),
    do: %{page | rendered: render(page.live)}

  @doc "Perform a live redirect. Not implemented in `Pages` because it's specific to LiveView."
  @spec live_redirect(Pages.Driver.t(), binary()) :: Pages.Driver.t()
  def live_redirect(page, destination_path),
    do: page.live |> Phoenix.LiveViewTest.live_redirect(to: destination_path) |> handle_rendered_result(page)

  @spec submit_form(Pages.Driver.t(), Hq.Css.selector()) :: Pages.Driver.t()
  def submit_form(%__MODULE__{} = page, selector) do
    page.live
    |> form(Hq.Css.selector(selector))
    |> render_submit()
    |> handle_rendered_result(page)
  end

  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), atom(), Pages.attrs_t()) ::
          Pages.Driver.t()
  def submit_form(%__MODULE__{} = page, selector, schema, attrs) do
    params = [{schema, Map.new(attrs)}]

    page.live
    |> form(Hq.Css.selector(selector), params)
    |> render_submit()
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), atom(), Pages.attrs_t()) ::
          Pages.Driver.t()
  def update_form(%__MODULE__{} = page, selector, schema, attrs) do
    params = [{schema, Map.new(attrs)}]

    page.live
    |> form(Hq.Css.selector(selector), params)
    |> render_change()
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @doc "Go to the given URL, assuming that it will be a new LiveView"
  def visit(%__MODULE__{} = page, path) do
    case new_live(page.conn, path) do
      {:error, {:live_redirect, %{to: new_path}}} -> new(page.conn, new_path)
      {:error, {:redirect, %{to: new_path}}} -> Pages.new(page.conn) |> Pages.visit(new_path)
      {:ok, view, html} -> %__MODULE__{conn: page.conn, live: view, rendered: html}
    end
  end

  # # #

  defp new_live(conn, path) do
    cond do
      is_binary(path) ->
        conn
        |> Pages.Shim.__dispatch(:get, path)
        |> Phoenix.LiveViewTest.__live__(path)

      is_nil(path) ->
        Phoenix.LiveViewTest.__live__(conn)

      true ->
        raise RuntimeError, "path must be nil or a binary, got: #{inspect(path)}"
    end
  end

  defp handle_rendered_result(rendered_result, %__MODULE__{} = page) do
    case rendered_result do
      rendered when is_binary(rendered) -> %{page | rendered: rendered}
      {:error, {:live_redirect, %{to: new_path}}} -> new(page.conn, new_path)
      {:error, {:redirect, %{to: new_path}}} -> Pages.new(page.conn) |> Pages.visit(new_path)
      {:ok, live, html} -> %{page | live: live, rendered: html}
    end
  end

  defp maybe_trigger_action(%__MODULE__{} = page, params) do
    case page |> Hq.find("[phx-trigger-action]") do
      element when not is_nil(element) ->
        page.live
        |> Phoenix.LiveViewTest.form("form[phx-trigger-action]", params)
        |> Pages.Shim.__follow_trigger_action(page.conn)
        |> Pages.new()

      _ ->
        page
    end
  end

  defimpl String.Chars, for: Pages.Driver.LiveView do
    def to_string(%Pages.Driver.LiveView{rendered: rendered}) when not is_nil(rendered),
      do: rendered

    def to_string(%Pages.Driver.LiveView{live: live}) when not is_nil(live),
      do: live |> Phoenix.LiveViewTest.render()
  end
end
