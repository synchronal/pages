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
  alias Pages.Driver

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

  @doc "Instantiates a new page."
  @spec new(Plug.Conn.t()) :: Pages.result()

  def new(%Driver{} = driver), do: driver

  def new(session) do
    drivers = Application.get_env(:pages, :drivers)

    driver =
      drivers
      |> Stream.filter(& &1.match?(session))
      |> Enum.reduce_while(nil, fn driver, _ ->
        case driver.new(session) do
          %Driver{} = driver -> {:halt, driver}
          {:ok, state} -> {:halt, Driver.new(driver, state)}
          :error -> {:cont, nil}
        end
      end)

    driver || raise(Pages.Error, "No driver matches for #{inspect(session)}")
  end

  @doc """
  Simulates clicking on an element at `selector` with title `title`.
  Set the `method` param to `:post` to click on a link that has `data-method=post`.
  """
  @spec click(Pages.Driver.t(), http_method(), text_filter(), Hq.Css.selector()) :: Pages.result()
  def click(%Driver{driver: module, state: state} = driver, method, title, selector),
    do: module.click(state, method, title, selector) |> merge(driver)

  @spec click(Pages.Driver.t(), http_method(), Hq.Css.selector()) :: Pages.result()
  def click(%Driver{driver: module, state: state} = driver, :get, selector),
    do: module.click(state, :get, nil, selector) |> merge(driver)

  def click(%Driver{driver: module, state: state} = driver, :post, selector),
    do: module.click(state, :post, nil, selector) |> merge(driver)

  @spec click(Pages.Driver.t(), text_filter(), Hq.Css.selector()) :: Pages.result()
  def click(%Driver{driver: module, state: state} = driver, title, selector),
    do: module.click(state, :get, title, selector) |> merge(driver)

  @spec click(Pages.Driver.t(), Hq.Css.selector()) :: Pages.result()
  def click(%Driver{driver: module, state: state} = driver, selector),
    do: module.click(state, :get, nil, selector) |> merge(driver)

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
  def handle_redirect(%Driver{driver: module, state: state} = driver), do: module.handle_redirect(state) |> merge(driver)

  @doc """
  Render a change to the element at `selector` with the value `value`. See `Phoenix.LiveViewTest.render_change/2` for
  a description of the `value` field.
  """
  @spec render_change(Pages.Driver.t(), Hq.Css.selector(), Enum.t()) :: Pages.result()
  def render_change(%Driver{driver: module, state: state} = driver, selector, value),
    do: module.render_change(state, selector, value) |> merge(driver)

  @doc """
  Performs an upload of a file input and renders the result. See `Phoenix.LiveViewTest.file_input/4` for
  a description of the `upload` field.
  """
  @spec render_upload(Pages.Driver.t(), live_view_upload(), binary(), integer()) :: Pages.result()
  def render_upload(%Driver{driver: module, state: state}, upload, entry_name, percent \\ 100),
    do: module.render_upload(state, upload, entry_name, percent)

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
  def render_hook(%Driver{driver: module, state: state}, event, value_attrs, opts \\ []),
    do: module.render_hook(state, event, value_attrs, opts)

  @doc "Re-renders the page."
  @spec rerender(Pages.Driver.t()) :: Pages.result()
  def rerender(%Driver{driver: module, state: state} = driver), do: module.rerender(state) |> merge(driver)

  @doc """
  Submits a form without specifying any attributes. This function will submit any values
  currently set in the form HTML.
  """
  @spec submit_form(Pages.Driver.t(), Hq.Css.selector()) :: Pages.result()
  def submit_form(%Driver{driver: module, state: state} = driver, selector),
    do: module.submit_form(state, selector) |> merge(driver)

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

  def submit_form(%Driver{driver: module, state: state} = driver, selector, attrs)
      when is_list(attrs) or is_map(attrs),
      do: module.submit_form(state, selector, attrs, []) |> merge(driver)

  def submit_form(%Driver{driver: module, state: state} = driver, selector, attrs, hidden_attrs)
      when is_list(attrs) or (is_map(attrs) and (is_list(hidden_attrs) or is_map(hidden_attrs))),
      do: module.submit_form(state, selector, attrs, hidden_attrs) |> merge(driver)

  def submit_form(%Driver{driver: module, state: state} = driver, selector, schema, attrs)
      when is_atom(schema) and (is_list(attrs) or is_map(attrs)),
      do: module.submit_form(state, selector, schema, attrs, []) |> merge(driver)

  def submit_form(%Driver{driver: module, state: state} = driver, selector, schema, form_attrs, hidden_attrs)
      when is_atom(schema) and (is_list(form_attrs) or is_map(form_attrs)),
      do: module.submit_form(state, selector, schema, form_attrs, hidden_attrs) |> merge(driver)

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

  def update_form(%Driver{driver: module, state: state} = driver, selector, schema, attrs, opts)
      when is_atom(schema) and (is_list(attrs) or is_map(attrs)) and is_list(opts) do
    module.update_form(state, selector, schema, attrs, opts) |> merge(driver)
  end

  def update_form(%Driver{driver: module, state: state} = driver, selector, schema, attrs)
      when is_atom(schema) and (is_list(attrs) or is_map(attrs)) do
    module.update_form(state, selector, schema, attrs, []) |> merge(driver)
  end

  def update_form(%Driver{driver: module, state: state} = driver, selector, attrs, opts)
      when (is_list(attrs) or is_map(attrs)) and is_list(opts) do
    module.update_form(state, selector, attrs, []) |> merge(driver)
  end

  def update_form(%Driver{driver: module, state: state} = driver, selector, attrs)
      when is_list(attrs) or is_map(attrs) do
    module.update_form(state, selector, attrs, []) |> merge(driver)
  end

  @doc "Visits `path`."
  @spec visit(Pages.Driver.t(), Path.t()) :: Pages.result()
  @spec visit(term(), Path.t()) :: Pages.result()
  def visit(%Plug.Conn{state: :unset} = conn, path), do: %{conn | request_path: path} |> Pages.new() |> flatten()

  def visit(%Pages.Driver{driver: module, state: state} = driver, path),
    do: module.visit(state, path) |> dbg() |> merge(driver)

  def visit(other, path), do: other |> Pages.new() |> dbg() |> visit(path) |> flatten()

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
  def with_child_component(%Driver{driver: module, state: state}, child_id, fun),
    do: module.with_child_component(state, child_id, fun)

  # # #

  defp merge(%Driver{} = state, _driver), do: state |> flatten()
  defp merge(state, driver), do: %{driver | state: state} |> flatten()

  defp flatten(%Driver{state: %Driver{} = state}), do: state |> flatten()
  defp flatten(other), do: other
end
