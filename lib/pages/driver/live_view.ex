defmodule Pages.Driver.LiveView do
  # @related [drivers](lib/pages/driver.ex)
  # @related [tests](test/pages/driver/live_view_test.exs)

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

  @impl Pages.Driver
  def match?(%Plug.Conn{assigns: %{live_module: _}}), do: true
  def match?(_), do: false

  @impl Pages.Driver
  def new(%Plug.Conn{assigns: %{live_module: _}} = conn),
    do: new(conn, conn.request_path, conn.query_params)

  def new(_), do: :error

  defp new(%Plug.Conn{} = conn, request_path, params) when is_binary(request_path) do
    {:ok,
     new_live(conn, request_path, params)
     |> handle_rendered_result(%__MODULE__{conn: conn})}
  end

  # # #

  @doc "Called from `Pages.click/4` when the given page is a LiveView."
  @impl Pages.Driver
  def click(%__MODULE__{} = page, :get, maybe_title, selector) do
    page.live
    |> LiveViewTest.element(Hq.Css.selector(selector), maybe_title)
    |> LiveViewTest.render_click()
    |> handle_rendered_result(page)
  end

  def click(%__MODULE__{} = page, :post, maybe_title, selector),
    do: Pages.Driver.Conn.click(page, :post, maybe_title, selector)

  @doc "Called from `Pages.handle_redirect/1` when the given page is a LiveView."
  @impl Pages.Driver
  def handle_redirect(page) do
    {path, _flash} = page.live |> Phoenix.LiveViewTest.assert_redirect()

    page.conn
    |> Phoenix.ConnTest.ensure_recycled()
    |> Pages.Shim.__retain_connect_params(page.conn)
    |> Pages.visit(path)
  end

  @doc "Called from `Pages.rerender/1` when the given page is a LiveView."
  @impl Pages.Driver
  def rerender(page),
    do: %{page | rendered: LiveViewTest.render(page.live)}

  @doc "Called from `Pages.render_change/3` when the given page is a LiveView."
  @impl Pages.Driver
  def render_change(%__MODULE__{} = page, selector, value) do
    page.live
    |> LiveViewTest.element(Hq.Css.selector(selector))
    |> LiveViewTest.render_change(value)
    |> handle_rendered_result(page)
  end

  @doc "Called from `Pages.render_hook/3` when the given page is a LiveView."
  @impl Pages.Driver
  def render_hook(%__MODULE__{} = page, event, value_attrs, options) do
    case Keyword.get(options, :target) do
      nil -> page.live
      target -> page.live |> LiveViewTest.element(target)
    end
    |> LiveViewTest.render_hook(event, value_attrs)
    |> handle_rendered_result(page)
  end

  @doc "Called from `Pages.render_upload/4` when the given page is a LiveView."
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
  def live_redirect(page, destination_path),
    do: page.live |> Phoenix.LiveViewTest.live_redirect(to: destination_path) |> handle_rendered_result(page)

  @doc "Called from `Pages.submit_form/2` when the given page is a LiveView."
  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector) do
    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector))
    |> LiveViewTest.render_submit()
    |> handle_rendered_result(page)
  end

  @doc "Called from `Pages.submit_form/4` and `Pages.submit_form/5` when the given page is a LiveView."
  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector, schema, form_attrs, hidden_attrs) do
    params = [{schema, Map.new(form_attrs)}]
    hidden_params = [{schema, Map.new(hidden_attrs)}]

    submit_form(page, selector, params, hidden_params)
  end

  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector, form_attrs, hidden_attrs) do
    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector), form_attrs)
    |> LiveViewTest.render_submit(Map.new(hidden_attrs))
    |> handle_rendered_result(page)
    |> maybe_trigger_action(form_attrs)
  end

  @doc "Called from `Pages.update_form/5` when the given page is a LiveView."
  @impl Pages.Driver
  def update_form(%__MODULE__{} = page, selector, schema, attrs, opts) do
    params = %{schema => Map.new(attrs)}

    update_form(page, selector, params, opts)
  end

  @impl Pages.Driver
  def update_form(%__MODULE__{} = page, selector, attrs, opts) do
    params =
      attrs
      |> Map.new()
      |> then(fn params ->
        case Keyword.get(opts, :target) do
          nil -> params
          target -> Map.put(params, :_target, target)
        end
      end)

    page.live
    |> LiveViewTest.form(Hq.Css.selector(selector))
    |> LiveViewTest.render_change(params)
    |> handle_rendered_result(page)
    |> maybe_trigger_action(params)
  end

  @doc """
  Initialize a `live` with the given path.

  This is called from `Pages.visit/2` when the conn indicates that the pages is a LiveView,
  and should only be called directly if the parent function does not work for some reason.
  """
  @impl Pages.Driver
  def visit(%__MODULE__{} = page, path) do
    uri = URI.parse(to_string(path))

    if uri.host in [nil, "localhost"] do
      new_live(page.conn, path, %{})
      |> dbg()
      |> handle_rendered_result(page)
    else
      {:error, :external, path}
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

  defp new_live(conn, path, params) do
    cond do
      is_binary(path) ->
        conn
        |> Phoenix.ConnTest.ensure_recycled()
        |> Pages.Shim.__dispatch(:get, path, params)
        |> then(fn
          %{assigns: %{live_module: _}} = new_conn ->
            new_conn
            |> Pages.Shim.__retain_connect_params(conn)
            |> Phoenix.LiveViewTest.__live__(path)

          conn ->
            conn
        end)

      is_nil(path) ->
        conn
        |> Phoenix.ConnTest.ensure_recycled()
        |> then(&Pages.Shim.__retain_connect_params(&1, conn))
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

        conn
        |> Pages.Shim.__retain_connect_params(page.conn)
        |> Pages.visit(to)

      {:error, {:redirect, %{to: new_path}}} ->
        page.conn
        |> Phoenix.ConnTest.ensure_recycled()
        |> Pages.Shim.__retain_connect_params(page.conn)
        |> Pages.visit(new_path)

      {:ok, live, html} ->
        %{page | live: live, rendered: html}

      %Plug.Conn{} = conn ->
        Pages.new(conn)
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

  defp maybe_trigger_action(page, _params), do: page

  defimpl String.Chars, for: Pages.Driver.LiveView do
    def to_string(%Pages.Driver.LiveView{rendered: rendered}) when not is_nil(rendered),
      do: rendered

    def to_string(%Pages.Driver.LiveView{live: live}) when not is_nil(live),
      do: live |> Phoenix.LiveViewTest.render()
  end
end
