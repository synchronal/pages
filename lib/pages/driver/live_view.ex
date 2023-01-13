defmodule Pages.Driver.LiveView do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix.LiveView pages.
  """

  @behaviour Pages.Driver

  alias Phoenix.LiveViewTest

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

  def new(%Plug.Conn{} = conn, {:error, {:live_redirect, %{to: new_path}}}),
    do: new(conn, new_path)

  # # #

  @doc "Called from `Pages.click/4` when the given page is a LiveView."
  @spec click(Pages.Driver.t(), Pages.http_method(), Pages.text_filter() | nil, Hq.Css.selector()) :: Pages.Driver.t()
  @impl Pages.Driver
  def click(%__MODULE__{} = page, :get, maybe_title, selector) do
    page.live
    |> LiveViewTest.element(Hq.Css.selector(selector), maybe_title)
    |> LiveViewTest.render_click()
    |> handle_rendered_result(page)
  end

  def click(%__MODULE__{} = page, :post, maybe_title, selector),
    do: Pages.Driver.Conn.click(page, :post, maybe_title, selector)

  @doc "Called from `Pages.rerender/1` when the given page is a LiveView."
  @spec rerender(Pages.Driver.t()) :: Pages.Driver.t()
  @impl Pages.Driver
  def rerender(page),
    do: %{page | rendered: LiveViewTest.render(page.live)}

  @doc "Called from `Paged.render_change/3` when the given page is a LiveView."
  @spec render_change(Pages.Driver.t(), Hq.Css.selector(), Enum.t()) :: Pages.Driver.t()
  @impl Pages.Driver
  def render_change(%__MODULE__{} = page, selector, value) do
    page.live
    |> LiveViewTest.element(Hq.Css.selector(selector))
    |> LiveViewTest.render_change(value)
    |> handle_rendered_result(page)
  end

  @doc "Called from `Paged.render_hook/3` when the given page is a LiveView."
  @spec render_hook(Pages.Driver.t(), binary(), Pages.attrs_t()) :: Pages.Driver.t()
  @impl Pages.Driver
  def render_hook(%__MODULE__{} = page, event, value_attrs) do
    page.live
    |> LiveViewTest.render_hook(event, value_attrs)
    |> handle_rendered_result(page)
  end

  @doc """
  Perform a live redirect to the given path.

  This is not implemented in `Pages` due to its specificity to LiveView and LiveViewTest.
  """
  @spec live_redirect(Pages.Driver.t(), binary()) :: Pages.Driver.t()
  def live_redirect(page, destination_path),
    do: page.live |> Phoenix.LiveViewTest.live_redirect(to: destination_path) |> handle_rendered_result(page)

  @doc "Called from `Pages.submit_form/2` when the given page is a LiveView."
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector()) :: Pages.Driver.t()
  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector) do
    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector))
    |> LiveViewTest.render_submit()
    |> handle_rendered_result(page)
  end

  @doc "Called from `Pages.submit_form/4` when the given page is a LiveView."
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), atom(), Pages.attrs_t()) ::
          Pages.Driver.t()
  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector, schema, attrs) do
    params = [{schema, Map.new(attrs)}]

    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector), params)
    |> LiveViewTest.render_submit()
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @doc "Called from `Pages.update_form/4` when the given page is a LiveView."
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), atom(), Pages.attrs_t()) ::
          Pages.Driver.t()
  @impl Pages.Driver
  def update_form(%__MODULE__{} = page, selector, schema, attrs) do
    params = [{schema, Map.new(attrs)}]

    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector), params)
    |> LiveViewTest.render_change()
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @doc """
  Initialize a `live` with the given path.

  This is called from `Pages.visit/2` when the conn indicates that the pages is a LiveView,
  and should only be called directly if the parent function does not work for some reason.
  """
  @spec visit(Pages.Driver.t(), binary()) :: Pages.Driver.t()
  @impl Pages.Driver
  def visit(%__MODULE__{} = page, path) do
    case new_live(page.conn, path) do
      {:error, {:live_redirect, %{to: new_path}}} -> new(page.conn, new_path)
      {:error, {:redirect, %{to: new_path}}} -> Pages.new(page.conn) |> Pages.visit(new_path)
      {:ok, view, html} -> %__MODULE__{conn: page.conn, live: view, rendered: html}
    end
  end

  @doc """
  Find a child component, and pass it as a new Page into the given function.

  Rerenders the top-level page upon completion. See `Pages.with_child_component/3`.
  """
  @impl Pages.Driver
  def with_child_component(%__MODULE__{live: view} = page, child_id, fun) when is_function(fun, 1) do
    child = Phoenix.LiveViewTest.find_live_child(view, child_id)

    if !child,
      do: raise(Pages.Error, "Expected to find a child component with id `#{child_id}`, but found nil")

    fun.(%{page | live: child})
    Pages.rerender(page)
  end

  # # #

  defp new_live(conn, path) do
    cond do
      is_binary(path) ->
        conn
        |> Phoenix.ConnTest.ensure_recycled()
        |> Pages.Shim.__dispatch(:get, path)
        |> Phoenix.LiveViewTest.__live__(path)

      is_nil(path) ->
        conn
        |> Phoenix.ConnTest.ensure_recycled()
        |> Phoenix.LiveViewTest.__live__()

      true ->
        raise RuntimeError, "path must be nil or a binary, got: #{inspect(path)}"
    end
  end

  defp handle_rendered_result(rendered_result, %__MODULE__{} = page) do
    case rendered_result do
      rendered when is_binary(rendered) ->
        %{page | rendered: rendered}

      {:error, {:live_redirect, opts}} ->
        endpoint = Pages.Shim.__endpoint()
        {conn, to} = Phoenix.LiveViewTest.__follow_redirect__(page.conn, endpoint, nil, opts)
        new(conn, to)

      {:error, {:redirect, %{to: new_path}}} ->
        Pages.new(page.conn) |> Pages.visit(new_path)

      {:ok, live, html} ->
        %{page | live: live, rendered: html}
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
