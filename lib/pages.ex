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

  @typedoc """
  In most cases, when interacting with pages, a new page will be returned (either a
  `%Pages.Driver.LiveView{}` or a `%Pages.Driver.Conn{}`). When actions redirect to
  an external URL, `Pages` functions will return a tuple with `{:error, :external, url}`
  """
  @type result() :: Pages.Driver.t() | {:error, :external, Path.t()}

  @type attrs_t() :: Keyword.t() | map()
  @type context_t() :: %{atom() => any()} | keyword()
  @type page_type_t() :: :live_view
  @type http_method() :: :get | :post
  @type live_view_upload() :: %Phoenix.LiveViewTest.Upload{}
  @type text_filter() :: binary() | Regex.t()

  @doc "Instantiates a new page."
  @spec new(Plug.Conn.t(), context_t()) :: Pages.result()
  def new(conn, context \\ %{})
  def new(%Plug.Conn{assigns: %{live_module: _}} = conn, context), do: Pages.Driver.LiveView.new(conn, context)
  def new(%Plug.Conn{} = conn, context), do: Pages.Driver.Conn.new(conn, context)

  @doc """
  Simulates clicking on an element at `selector` with title `title`.
  Set the `method` param to `:post` to click on a link that has `data-method=post`.
  """
  @spec click(Pages.Driver.t(), http_method(), text_filter(), Hq.Css.selector()) :: Pages.result()
  def click(%module{} = page, method, title, selector), do: module.click(page, method, title, selector)

  @spec click(Pages.Driver.t(), http_method(), Hq.Css.selector()) :: Pages.result()
  def click(%module{} = page, :get, selector), do: module.click(page, :get, nil, selector)
  def click(%module{} = page, :post, selector), do: module.click(page, :post, nil, selector)

  @spec click(Pages.Driver.t(), text_filter(), Hq.Css.selector()) :: Pages.result()
  def click(%module{} = page, title, selector), do: module.click(page, :get, title, selector)

  @spec click(Pages.Driver.t(), Hq.Css.selector()) :: Pages.result()
  def click(%module{} = page, selector), do: module.click(page, :get, nil, selector)

  @doc "Clears out any params set via `Phoenix.LiveViewTest.put_connect_params/2`"
  @spec clear_connect_params(Pages.Driver.t()) :: Pages.result()
  def clear_connect_params(%{conn: conn} = page) do
    private = Map.drop(conn.private, [:live_view_connect_params])
    %{page | conn: %{conn | private: private}}
  end

  @doc """
  Handles cases where the server issues a redirect to the client without a synchronous interaction from the
  user. This may be used to handle redirects issued from `c:Phoenix.LiveView.handle_info/2` callbacks, for instance.
  """
  @spec handle_redirect(Pages.Driver.t()) :: Pages.result()
  def handle_redirect(%module{} = page), do: module.handle_redirect(page)

  @doc """
  Attempt to open the current page in a web browser.
  """
  @spec open_browser(Pages.Driver.t()) :: Pages.Driver.t()
  def open_browser(%module{} = page), do: module.open_browser(page)

  @doc """
  Render a change to the element at `selector` with the value `value`. See `Phoenix.LiveViewTest.render_change/2` for
  a description of the `value` field.
  """
  @spec render_change(Pages.Driver.t(), Hq.Css.selector(), Enum.t()) :: Pages.result()
  def render_change(%module{} = page, selector, value), do: module.render_change(page, selector, value)

  @doc """
  Performs an upload of a file input and renders the result. See `Phoenix.LiveViewTest.file_input/4` for
  a description of the `upload` field.
  """
  @spec render_upload(Pages.Driver.t(), live_view_upload(), binary(), integer()) :: Pages.result()
  def render_upload(%module{} = page, upload, entry_name, percent \\ 100),
    do: module.render_upload(page, upload, entry_name, percent)

  @doc """
  Sends a hook event to the live view.

  ## Arguments

  | name        | decription |
  | ----------- | ---------- |
  | page        | The current page struct. |
  | event       | The event name to send to `handle_event`. |
  | value_attrs | A map of params to send to `handle_event`. |
  | opts        | An optional keyword list of options. |

  ## Options

  | name   | description |
  | ------ | ----------- |
  | target | The selector of an embedded live componont to receive the event. Example: `#sub-module` |

  See `Phoenix.LiveViewTest.render_hook/3` for more information.
  """
  @spec render_hook(Pages.Driver.t(), binary(), attrs_t(), keyword()) :: Pages.result()
  def render_hook(%module{} = page, event, value_attrs, opts \\ []),
    do: module.render_hook(page, event, value_attrs, opts)

  @doc "Re-renders the page."
  @spec rerender(Pages.Driver.t()) :: Pages.result()
  def rerender(%module{} = page), do: module.rerender(page)

  @doc """
  Submits a form without specifying any attributes. This function will submit any values
  currently set in the form HTML.
  """
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector()) :: Pages.result()
  def submit_form(%module{} = page, selector), do: module.submit_form(page, selector)

  @doc """
  Fills in a form with `attributes` and submits it. Hidden parameters can by send by including
  a fifth enumerable.

  ## Arguments

  | name         | decription |
  | ------------ | ---------- |
  | page         | The current page struct. |
  | selector     | A CSS selector matching the form. |
  | schema       | An optional atom representing the schema of the form. Attributes will be nested under this key when submitted. See [Schema](#submit_form/4-schema). |
  | attrs        | A map of attributes to send. |
  | hidden_attrs | An optional map or keyword of hidden values to include. |

  ## Schema

  This atom determines the key under which attrs will be nested when sent to the server,
  and corresponds to the atom which an `t:Ecto.Changeset.t/0` serializes to, or the value
  of `:as` passed to `Phoenix.HTML.FormData.to_form/4`.

  When a schema is passed, the form attrs will be received as nested params under the schema
  key.

  If one wishes to construct the full nested map of attrs, then the schema may be omitted.

  ## Examples

  ``` elixir
  iex> conn = Phoenix.ConnTest.build_conn()
  iex> page = Pages.visit(conn, "/live/form")
  iex> Pages.submit_form(page, "#form", :foo, value: "rerender")

  iex> conn = Phoenix.ConnTest.build_conn()
  iex> page = Pages.visit(conn, "/live/form")
  iex> Pages.submit_form(page, "#form", foo: [value: "rerender"])

  ```

  ## Notes

  When used with LiveView, this will trigger `phx-submit` with the specified attributes,
  and handles `phx-trigger-action` if present.
  """
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), attrs :: attrs_t()) ::
          Pages.result()
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), attrs :: attrs_t(), hidden_attrs :: attrs_t()) ::
          Pages.result()
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), schema :: atom(), attrs :: attrs_t()) ::
          Pages.result()
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), schema :: atom(), attrs :: attrs_t(), hidden_attrs :: attrs_t()) ::
          Pages.result()

  def submit_form(%module{} = page, selector, attrs)
      when is_list(attrs) or is_map(attrs),
      do: module.submit_form(page, selector, attrs, [])

  def submit_form(%module{} = page, selector, attrs, hidden_attrs)
      when is_list(attrs) or (is_map(attrs) and (is_list(hidden_attrs) or is_map(hidden_attrs))),
      do: module.submit_form(page, selector, attrs, hidden_attrs)

  def submit_form(%module{} = page, selector, schema, attrs)
      when is_atom(schema) and (is_list(attrs) or is_map(attrs)),
      do: module.submit_form(page, selector, schema, attrs, [])

  def submit_form(%module{} = page, selector, schema, form_attrs, hidden_attrs)
      when is_atom(schema) and (is_list(form_attrs) or is_map(form_attrs)),
      do: module.submit_form(page, selector, schema, form_attrs, hidden_attrs)

  @doc """
  Updates fields in a form with `attributes`, without submitting the form.

  ## Arguments

  | name     | decription |
  | -------- | ---------- |
  | page     | The current page struct. |
  | selector | A CSS selector matching the form. |
  | schema   | An optional atom representing the schema of the form. Attributes will be nested under this key when submitted. See [Schema](#submit_form/4-schema). |
  | attrs    | A map of attributes to send. |
  | opts     | A keyword list of options. |

  ## Options

  | name   | type             | description |
  | ------ | ---------------- | ----------- |
  | target | `list(binary())` | A list to be sent in the `_target` of the form params, indicating which field has been changes. |

  ## Schema

  This atom determines the key under which attrs will be nested when sent to the server,
  and corresponds to the atom which an `t:Ecto.Changeset.t/0` serializes to, or the value
  of `:as` passed to `Phoenix.HTML.FormData.to_form/4`.

  When a schema is passed, the form attrs will be received as nested params under the schema
  key.

  If one wishes to construct the full nested map of attrs, then the schema may be omitted.

  ## Examples

  ``` elixir
  iex> conn = Phoenix.ConnTest.build_conn()
  iex> page = Pages.visit(conn, "/live/form")
  iex> Pages.update_form(page, "#form", :my_form, value: "baz")

  iex> conn = Phoenix.ConnTest.build_conn()
  iex> page = Pages.visit(conn, "/live/form")
  iex> Pages.update_form(page, "#form", my_form: [value: "baz"])

  ```

  ## Notes

  When used with LiveView, this will trigger `phx-change` with the specified attributes,
  and handles `phx-trigger-action` if present.
  """
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), schema :: atom(), attrs :: attrs_t(), opts :: keyword()) ::
          Pages.result()
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), schema :: atom(), attrs :: attrs_t()) ::
          Pages.result()
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), attrs :: attrs_t(), opts :: keyword()) ::
          Pages.result()
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), attrs :: attrs_t()) ::
          Pages.result()

  def update_form(%module{} = page, selector, schema, attrs, opts)
      when is_atom(schema) and (is_list(attrs) or is_map(attrs)) and is_list(opts) do
    module.update_form(page, selector, schema, attrs, opts)
  end

  def update_form(%module{} = page, selector, schema, attrs)
      when is_atom(schema) and (is_list(attrs) or is_map(attrs)) do
    module.update_form(page, selector, schema, attrs, [])
  end

  def update_form(%module{} = page, selector, attrs, opts)
      when (is_list(attrs) or is_map(attrs)) and is_list(opts) do
    module.update_form(page, selector, attrs, [])
  end

  def update_form(%module{} = page, selector, attrs)
      when is_list(attrs) or is_map(attrs) do
    module.update_form(page, selector, attrs, [])
  end

  @doc "Visits `path`."
  @spec visit(Pages.Driver.t(), Path.t(), context_t()) :: Pages.result()
  @spec visit(Plug.Conn.t(), Path.t(), context_t()) :: Pages.result()
  def visit(%Plug.Conn{} = conn, path, context), do: %{conn | request_path: path} |> Pages.new(context)
  def visit(%module{} = page, path, context), do: module.visit(%{page | context: context}, path)

  @spec visit(Pages.Driver.t(), Path.t()) :: Pages.result()
  @spec visit(Plug.Conn.t(), Path.t()) :: Pages.result()

  def visit(%Plug.Conn{} = conn, path), do: %{conn | request_path: path} |> Pages.new(%{})
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
