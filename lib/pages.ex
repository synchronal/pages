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
  @type http_method() :: :get | :post
  @type text_filter() :: binary() | Regex.t()

  @doc "Instantiates a new page."
  @spec new(Plug.Conn.t()) :: Pages.Driver.t()
  def new(%Plug.Conn{assigns: %{live_module: _}} = conn), do: Pages.Driver.LiveView.new(conn)
  def new(%Plug.Conn{} = conn), do: Pages.Driver.Conn.new(conn)

  @doc """
  Simulates clicking on an element at `selector` with title `title`.
  Set the `method` param to `:post` to click on a link that has `data-method=post`.
  """
  @spec click(Pages.Driver.t(), http_method(), text_filter(), Hq.Css.selector()) :: Pages.Driver.t()
  def click(%module{} = page, method, title, selector), do: module.click(page, method, title, selector)

  @spec click(Pages.Driver.t(), http_method(), Hq.Css.selector()) :: Pages.Driver.t()
  def click(%module{} = page, :get, selector), do: module.click(page, :get, nil, selector)
  def click(%module{} = page, :post, selector), do: module.click(page, :post, nil, selector)

  @spec click(Pages.Driver.t(), text_filter(), Hq.Css.selector()) :: Pages.Driver.t()
  def click(%module{} = page, title, selector), do: module.click(page, :get, title, selector)

  @spec click(Pages.Driver.t(), Hq.Css.selector()) :: Pages.Driver.t()
  def click(%module{} = page, selector), do: module.click(page, :get, nil, selector)

  @doc """
  Render a change to the element at `selector` with the value `value`. See `Phoenix.LiveViewTest.render_change/2` for
  a description of the `value` field.
  """
  @spec render_change(Pages.Driver.t(), Hq.Css.selector(), Enum.t()) :: Pages.Driver.t()
  def render_change(%module{} = page, selector, value), do: module.render_change(page, selector, value)

  @doc """
  Sends a hook event to the live view. See `Phoenix.LiveViewTest.render_hook/3` for more information.
  """
  @spec render_hook(Pages.Driver.t(), binary(), attrs_t()) :: Pages.Driver.t()
  def render_hook(%module{} = page, event, value_attrs), do: module.render_hook(page, event, value_attrs)

  @doc "Re-renders the page."
  @spec rerender(Pages.Driver.t()) :: Pages.Driver.t()
  def rerender(%module{} = page), do: module.rerender(page)

  @doc """
  Submits a form without specifying any attributes. This function will submit any values
  currently set in the form HTML.
  """
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector()) :: Pages.Driver.t()
  def submit_form(%module{} = page, selector), do: module.submit_form(page, selector)

  @doc """
  Fills in a form with `attributes` and submits it.

  ## Arguments

  | name     | decription |
  | -------- | ---------- |
  | page     | The current page struct. |
  | selector | A CSS selector matching the form. |
  | schema   | An atom representing the schema of the form. Attributes will be nested under this key when submitted. See [Schema](#submit_form/4-schema). |
  | attrs    | A map of attributes to send. |

  ## Schema

  This atom determines the key under which attrs will be nested when sent to the server,
  and corresponds to the atom which an `t:Ecto.Changeset.t/0` serializes to, or the value
  of `:as` passed to `Phoenix.HTML.Form.form_for/4`.

  ## Notes

  When used with LiveView, this will trigger `phx-submit` with the specified attributes,
  and handles `phx-trigger-action` if present.
  """
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), atom(), attrs_t()) :: Pages.Driver.t()
  def submit_form(%module{} = page, selector, schema, attrs), do: module.submit_form(page, selector, schema, attrs)

  @doc """
  Fills in a form with `attributes` without submitting it.

  ## Arguments

  See `submit_form/4` for a full description of arguments.

  ## Notes

  When used with LiveView, this will trigger `phx-change` with the specified attributes,
  and handles `phx-trigger-action` if present.
  """
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), atom(), attrs_t()) :: Pages.Driver.t()
  def update_form(%module{} = page, selector, schema, attrs), do: module.update_form(page, selector, schema, attrs)

  @doc "Visits `path`."
  @spec visit(Pages.Driver.t(), Path.t()) :: Pages.Driver.t()
  def visit(%module{} = page, path), do: module.visit(page, path)

  @doc """
  Finds a phoenix component with an id matching `child_id`, and passes it to the given
  function. This is helpful when a site implements stateful LiveView components, and
  messages should be directed to a process other than the parent LiveView pid.

  ## Examples

  ```elixir
  Pages.with_child_component(page, "chat-component", fn child ->
    Pages.submit_form(child,
      [test_role: "new-chat-message"],
      :chat_message,
      contents: "Hi there!")
  end)
  ```
  """
  @spec with_child_component(Pages.Driver.t(), child_id :: binary(), (Pages.Driver.t() -> term())) :: Pages.Driver.t()
  def with_child_component(%module{} = page, child_id, fun), do: module.with_child_component(page, child_id, fun)
end
