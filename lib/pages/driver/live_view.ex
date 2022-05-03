defmodule Pages.Driver.LiveView do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix.LiveView pages.
  """

  @behaviour Pages.Driver

  import Phoenix.LiveViewTest

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

  @spec click(Pages.Driver.t(), binary(), Pages.Css.selector()) :: Pages.Driver.t()
  def click(%__MODULE__{} = page, title, selector) do
    page.live
    |> element(Pages.Css.query(selector), title)
    |> render_click()
    |> handle_rendered_result(page)
  end

  @spec submit_form(Pages.Driver.t(), Pages.Css.selector()) :: Pages.Driver.t()
  def submit_form(%__MODULE__{} = page, selector) do
    page.live
    |> form(Pages.Css.query(selector))
    |> render_submit()
    |> handle_rendered_result(page)
  end

  @spec submit_form(Pages.Driver.t(), Pages.Css.selector(), atom(), Pages.attrs_t()) ::
          Pages.Driver.t()
  def submit_form(%__MODULE__{} = page, selector, schema, attrs) do
    params = [{schema, Map.new(attrs)}]

    page.live
    |> form(Pages.Css.query(selector), params)
    |> render_submit()
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @spec update_form(Pages.Driver.t(), Pages.Css.selector(), atom(), Pages.attrs_t()) ::
          Pages.Driver.t()
  def update_form(%__MODULE__{} = page, selector, schema, attrs) do
    params = [{schema, Map.new(attrs)}]

    page.live
    |> form(Pages.Css.query(selector), params)
    |> render_change()
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @doc "Go to the given URL, assuming that it will be a new LiveView"
  def visit(%__MODULE__{} = page, path) do
    {:ok, view, html} = new_live(page.conn, path)
    %__MODULE__{conn: page.conn, live: view, rendered: html}
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
      {:error, {:live_redirect, %{to: new_path}}} -> new(page.conn, new_path)
      rendered -> %{page | rendered: rendered}
    end
  end

  defp maybe_trigger_action(%__MODULE__{} = page, params) do
    case page |> Pages.Html.find("[phx-trigger-action]") do
      element when not is_nil(element) ->
        page.live
        |> Phoenix.LiveViewTest.form("form[phx-trigger-action]", params)
        |> Pages.Shim.__follow_trigger_action(page.conn)
        |> Pages.new()

      _ ->
        page
    end
  end

  defimpl String.Chars do
    def to_string(%Pages.Driver.LiveView{rendered: rendered}) when not is_nil(rendered),
      do: rendered

    def to_string(%Pages.Driver.LiveView{live: live}) when not is_nil(live),
      do: live |> Phoenix.LiveViewTest.render()
  end
end
