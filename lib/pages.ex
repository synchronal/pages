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

  require Phoenix.ConnTest

  @endpoint Application.compile_env(:pages, :phoenix_endpoint)

  @typedoc """
  In most cases, when interacting with pages, a new page will be returned (either a
  `%Pages.Driver.LiveView{}` or a `%Pages.Driver.Conn{}`). When actions redirect to
  an external URL, `Pages` functions will return a tuple with `{:error, :external, url}`
  """
  @type result() :: Pages.Driver.t() | {:error, :external, Path.t()}

  @type attrs_t() :: Keyword.t() | map()
  @type page_type_t() :: :live_view
  @type http_method() :: :get | :post
  @type live_view_upload() :: %Phoenix.LiveViewTest.Upload{}
  @type text_filter() :: binary() | Regex.t()

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
  Fills in a form with `attributes` and submits it. Hidden parameters can by send by including
  a fifth enumerable.

  ## Arguments

  | name         | decription |
  | ------------ | ---------- |
  | page         | The current page struct. |
  | selector     | A CSS selector matching the form. |
  | schema       | An atom representing the schema of the form. Attributes will be nested under this key when submitted. See [Schema](#submit_form/4-schema). |
  | attrs        | A map of attributes to send. |
  | hidden_attrs | An optional map or keyword of hidden values to include. |

  ## Schema

  This atom determines the key under which attrs will be nested when sent to the server,
  and corresponds to the atom which an `t:Ecto.Changeset.t/0` serializes to, or the value
  of `:as` passed to `Phoenix.HTML.Form.form_for/4`.

  ## Notes

  When used with LiveView, this will trigger `phx-submit` with the specified attributes,
  and handles `phx-trigger-action` if present.
  """
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), atom(), attrs_t(), attrs_t()) :: Pages.result()
  def submit_form(page, selector, schema, form_attrs, hidden_attrs) do
    params = %{schema => Map.new(form_attrs)}
    hidden_params = %{schema => Map.new(hidden_attrs)}
    submit_form(page, selector, params, hidden_params)
  end

  @doc "See `Pages.submit_form/5` for more information."
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector(), atom(), attrs_t(), keyword()) :: Pages.result()
  def submit_form(%module{} = page, selector, params \\ %{}, hidden_attrs \\ []) do
    module.submit_form(page, selector, params, Map.new(hidden_attrs))
  end


  @doc """
  Updates fields in a form with `attributes` without submitting it.

  ## Arguments

  | name     | decription |
  | -------- | ---------- |
  | page     | The current page struct. |
  | selector | A CSS selector matching the form. |
  | schema   | An atom representing the schema of the form. Attributes will be nested under this key when submitted. See [Schema](#submit_form/4-schema). |
  | attrs    | A map of attributes to send. |
  | opts     | A keyword list of options. |

  ## Options

  | name   | type             | description |
  | ------ | ---------------- | ----------- |
  | target | `list(binary())` | A list to be sent in the `_target` of the form params, indicating which field has been changes. |

  ## Schema

  This atom determines the key under which attrs will be nested when sent to the server,
  and corresponds to the atom which an `t:Ecto.Changeset.t/0` serializes to, or the value
  of `:as` passed to `Phoenix.HTML.Form.form_for/4`.

  ## Notes

  When used with LiveView, this will trigger `phx-change` with the specified attributes,
  and handles `phx-trigger-action` if present.
  """
  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), atom(), attrs_t(), keyword()) :: Pages.result()
  def update_form(page, selector, schema, attrs, opts) do
    params = %{schema => Map.new(attrs)}
    update_form(page, selector, params, opts)
  end

  @spec update_form(Pages.Driver.t(), Hq.Css.selector(), attrs_t(), keyword()) :: Pages.result()
  def update_form(%module{} = page, selector, params, opts \\ []),
    do: module.update_form(page, selector, params, opts)

  @doc "Visits `path`."
  @spec visit(Plug.Conn.t() | Pages.Driver.t(), Path.t()) :: Pages.result()
  def visit(%{conn: conn} = _page, path), do: visit(conn, path)

  def visit(%Plug.Conn{} = conn, path) do
    case Phoenix.ConnTest.get(conn, path) do
      %{status: 302} = conn ->
        path = Phoenix.ConnTest.redirected_to(conn)

        if String.starts_with?(path, "http") do
          {:error, :external, path}
        else
          visit(conn, path)
        end

      %{assigns: %{live_module: _}} = conn ->
        Pages.Driver.LiveView.build(conn)

      conn ->
        Pages.Driver.Conn.build(conn)
    end
  end


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
