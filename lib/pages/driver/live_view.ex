defmodule Pages.Driver.LiveView do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix.LiveView pages.
  """

  @behaviour Pages.Driver

  alias HtmlQuery, as: Hq
  alias Phoenix.LiveViewTest

  defstruct ~w[conn live rendered]a

  @type t() :: %__MODULE__{
          conn: Plug.Conn.t(),
          live: any(),
          rendered: binary() | nil
        }

  def build(%Plug.Conn{} = conn) do
    case Phoenix.LiveViewTest.__live__(conn) do
      {:ok, view, html} ->
        %__MODULE__{live: view, conn: conn, rendered: html}

      {:error, {:live_redirect, %{to: new_path}}} ->
        Pages.visit(conn, new_path)

      {:error, {:redirect, %{to: new_path}}} ->
        Pages.visit(conn, new_path)
    end
  end

  # # #

  @doc "Called from `Pages.click/4` when the given page is a LiveView."
  @spec click(Pages.Driver.t(), Pages.http_method(), Pages.text_filter() | nil, Hq.Css.selector()) ::
          Pages.result()
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
  @spec rerender(Pages.Driver.t()) :: Pages.result()
  @impl Pages.Driver
  def rerender(page),
    do: %{page | rendered: LiveViewTest.render(page.live)}

  @doc "Called from `Paged.render_change/3` when the given page is a LiveView."
  @spec render_change(Pages.Driver.t(), Hq.Css.selector(), Enum.t()) :: Pages.result()
  @impl Pages.Driver
  def render_change(%__MODULE__{} = page, selector, value) do
    page.live
    |> LiveViewTest.element(Hq.Css.selector(selector))
    |> LiveViewTest.render_change(value)
    |> handle_rendered_result(page)
  end

  @doc "Called from `Paged.render_hook/3` when the given page is a LiveView."
  @spec render_hook(Pages.Driver.t(), binary(), Pages.attrs_t(), keyword()) :: Pages.result()
  @impl Pages.Driver
  def render_hook(%__MODULE__{} = page, event, value_attrs, options) do
    case Keyword.get(options, :target) do
      nil -> page.live
      target -> page.live |> LiveViewTest.element(target)
    end
    |> LiveViewTest.render_hook(event, value_attrs)
    |> handle_rendered_result(page)
  end

  @doc "Called from `Paged.render_upload/4` when the given page is a LiveView."
  @spec render_upload(Pages.Driver.t(), Pages.live_view_upload(), binary(), integer()) :: Pages.result()
  @impl Pages.Driver
  def render_upload(%__MODULE__{} = page, %Phoenix.LiveViewTest.Upload{} = upload, entry_name, percent) do
    upload
    |> LiveViewTest.render_upload(entry_name, percent)
    |> handle_rendered_result(page)
  end

  @doc """
  Perform a live redirect to the given path.

  When issuing a live_redirect from one live view to another live view where the
  routes cross between two `live_session`s, then live view will not just remount
  the socket, but will issue a redirect. In this case, if the test pages have been
  initialized via `Phoenix.ConnTest.build_conn/0`, the test adapter will have the
  URI host set to be `www.example.com`... the live_redirect will be seen as an
  external redirect.

  When using `live_redirect/2` between two live sessions, ensure that the initial
  test setup (for example in ConnCase) instead calls
  `Phoenix.ConnTest.build_conn(:get, "http://localhost:4002/")`, so that redirects
  are seen as internal redirects.

  This is not implemented in `Pages` due to its specificity to LiveView and LiveViewTest.
  """
  @spec live_redirect(Pages.Driver.t(), binary()) :: Pages.result()
  def live_redirect(page, destination_path),
    do: page.live |> Phoenix.LiveViewTest.live_redirect(to: destination_path) |> handle_rendered_result(page)

  @doc "Called from `Pages.submit_form/4` and `Pages.submit_form/5` when the given page is a LiveView."
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), Pages.attrs_t(), Pages.attrs_t()) :: Pages.result()
  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector, %{} = params, %{} = hidden_attrs) do
    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector), params)
    |> LiveViewTest.render_submit(hidden_attrs)
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @doc "Called from `Pages.update_form/4` when the given page is a LiveView."
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), Pages.attrs_t(), keyword()) :: Pages.result()
  @impl Pages.Driver
  def update_form(%__MODULE__{} = page, selector, params, opts) do
    params =
      case Keyword.get(opts, :target) do
        nil -> params
        target -> Map.put(params, :_target, target)
      end

    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector))
    |> LiveViewTest.render_change(params)
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
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

  defp handle_rendered_result(rendered_result, %__MODULE__{} = page) do
    case rendered_result do
      rendered when is_binary(rendered) ->
        %{page | rendered: rendered}

      {:error, {:live_redirect, opts}} ->
        endpoint = Pages.Shim.__endpoint()
        {conn, to} = Phoenix.LiveViewTest.__follow_redirect__(page.conn, endpoint, nil, opts)
        conn = Pages.Shim.__retain_connect_params(conn, page.conn)
        Pages.visit(conn, to)

      {:error, {:redirect, %{to: new_path}}} ->
        Pages.visit(page.conn, new_path)

      {:ok, live, html} ->
        %{page | live: live, rendered: html}
    end
  end

  defp maybe_trigger_action({:error, type, value}, _params), do: {:error, type, value}

  defp maybe_trigger_action(%__MODULE__{} = page, params) do
    case page |> Hq.find("[phx-trigger-action]") do
      element when not is_nil(element) ->
        page.live
        |> Phoenix.LiveViewTest.form("form[phx-trigger-action]", params)
        |> Pages.Shim.__follow_trigger_action(page.conn)
        |> build()

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
