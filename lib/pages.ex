defmodule Pages do
  # @related [test](test/pages_test.exs)

  @moduledoc """
  Entry point for interacting with pages.

  Pages are built around `t:Pages.Driver.t/0` structs. Drivers hold state about
  the current connection, implement `@behavior Pages.Driver` and must implement
  the `String.Chars` protocol to transform themselves into HTML.

  ## Available drivers

  - `t:Pages.Driver.Conn.t/0` - Given a `t:Plug.Conn.t/0`, this driver will be used.
  - `t:Pages.Driver.LiveView.t/0` - Given a `t:Plug.Conn.t/0` with inner data that
    appears as if a `Phoenix.LiveView` is configured, this driver will be used.
  """

  alias HtmlQuery, as: Hq

  @type attrs_t() :: Keyword.t() | map()
  @type page_type_t() :: :live_view

  @doc "Instantiates a new page."
  @spec new(Plug.Conn.t()) :: Pages.Driver.t()
  def new(%Plug.Conn{assigns: %{live_module: _}} = conn), do: Pages.Driver.LiveView.new(conn)
  def new(%Plug.Conn{} = conn), do: Pages.Driver.Conn.new(conn)

  @doc """
  Simulates clicking on an element at `selector` with title `title`.
  Set the `method` param to `:post` to click on a link that has `data-method=post`.
  """
  @spec click(Pages.Driver.t(), :get | :post, binary(), Hq.Css.selector()) :: Pages.Driver.t()
  def click(%module{} = page, method \\ :get, title, selector), do: module.click(page, method, title, selector)

  @doc "Re-renders the page"
  @spec rerender(Pages.Driver.t()) :: Pages.Driver.t()
  def rerender(%module{} = page), do: module.rerender(page)

  @doc "Submits a form without specifying any attributes."
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector()) :: Pages.Driver.t()
  def submit_form(%module{} = page, selector), do: module.submit_form(page, selector)

  @doc "Fills in a form with `attributes` and submits it."
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), atom(), attrs_t()) :: Pages.Driver.t()
  def submit_form(%module{} = page, selector, schema, attrs), do: module.submit_form(page, selector, schema, attrs)

  @doc "Fills in a form with `attributes` without submitting it."
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), atom(), attrs_t()) :: Pages.Driver.t()
  def update_form(%module{} = page, selector, schema, attrs), do: module.update_form(page, selector, schema, attrs)

  @doc "Visits `path`."
  @spec visit(Pages.Driver.t(), Path.t()) :: Pages.Driver.t()
  def visit(%module{} = page, path), do: module.visit(page, path)

  @spec with_child_component(Pages.Driver.t(), child_id :: binary(), (Pages.Driver.t() -> term())) :: Pages.Driver.t()
  def with_child_component(%module{} = page, child_id, fun), do: module.with_child_component(page, child_id, fun)
end
