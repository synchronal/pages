defmodule Pages.Driver.Conn do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix controllers.
  """

  @behaviour Pages.Driver

  alias HtmlQuery, as: Hq

  defstruct conn: nil,
            context: %{}

  @type t() :: %__MODULE__{
          conn: Plug.Conn.t(),
          context: %{atom() => any()}
        }

  def new(conn, context \\ %{})

  def new(%Plug.Conn{state: :unset} = conn, context) do
    conn
    |> Pages.Shim.__dispatch(:get, conn.request_path, conn.path_params)
    |> Pages.new(context)
  end

  def new(%Plug.Conn{status: status_code} = conn, context) when status_code in [301, 302] do
    redirect = Phoenix.ConnTest.redirected_to(conn, status_code)
    __struct__(conn: conn, context: Map.new(context)) |> visit(redirect)
  end

  def new(%Plug.Conn{} = conn, context),
    do: __struct__(conn: conn, context: Map.new(context))

  # # #

  @doc "Simulates clicking on an element at `selector` with title `title`."
  @spec click(Pages.Driver.t(), Pages.http_method(), Pages.text_filter() | nil, Hq.Css.selector()) :: Pages.result()
  @impl Pages.Driver
  def click(page, :get, maybe_title, selector) do
    link = page |> Hq.find!(selector)
    refute_link_method(link)

    if title = maybe_title do
      assert_link_text(link, title)
    end

    page.conn
    |> Pages.Shim.__dispatch(:get, Hq.attr(link, :href))
    |> then(&Pages.Shim.__retain_connect_params(&1, page.conn))
    |> Pages.new(page.context)
  end

  def click(page, :post, maybe_title, selector) do
    link = page |> Hq.find!(selector)
    assert_link_method(link, "post")

    if title = maybe_title do
      assert_link_text(link, title)
    end

    page.conn
    |> Pages.Shim.__dispatch(:post, Hq.attr(link, :href), %{
      "_csrf_token" => Hq.attr(link, "data-csrf"),
      "_method" => "post"
    })
    |> then(&Pages.Shim.__retain_connect_params(&1, page.conn))
    |> Pages.new(page.context)
  end

  @doc """
  Not yet implemented for this driver.
  """
  @impl Pages.Driver
  @spec open_browser(Pages.Driver.t()) :: Pages.Driver.t()
  def open_browser(_page),
    do: raise("Not yet implemented for this driver")

  @impl Pages.Driver
  def rerender(page) do
    path =
      [page.conn.request_path, page.conn.query_string]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("?")

    visit(page, path)
  end

  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector) do
    case Pages.Form.build(page, selector) do
      {:ok, form} ->
        {action, params} = Pages.Form.to_post(form)

        page.conn
        |> Pages.Shim.__dispatch(:post, action, params)
        |> then(&Pages.Shim.__retain_connect_params(&1, page.conn))
        |> Pages.new(page.context)

      {:error, reason} ->
        error!(page, reason)
    end
  end

  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector, attrs, _hidden_attrs) do
    page = update_form(page, selector, attrs, [])
    submit_form(page, selector)
  end

  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector, schema, attrs, _hidden_attrs) do
    page = update_form(page, selector, schema, attrs, [])
    submit_form(page, selector)
  end

  @impl Pages.Driver
  def update_form(%__MODULE__{} = page, selector, schema, form_data, opts) do
    form_data = %{schema => Moar.Map.deep_atomize_keys(form_data)}
    update_form(page, selector, form_data, opts)
  end

  @impl Pages.Driver
  def update_form(%__MODULE__{} = page, selector, form_data, _opts) do
    form_data = Moar.Map.deep_atomize_keys(form_data)

    with {:ok, form} <- Pages.Form.build(page, selector),
         {:ok, form} <- Pages.Form.set(form, form_data),
         {:ok, html} <- Pages.Form.update_html(form, page.conn.resp_body) do
      conn = %{page.conn | resp_body: html}

      %{page | conn: conn}
    else
      {:error, reason} -> error!(page, reason)
    end
  end

  @impl Pages.Driver
  def visit(%__MODULE__{} = page, path) do
    uri = URI.parse(to_string(path))

    if uri.host in [nil, "localhost"] do
      page.conn
      |> Pages.Shim.__dispatch(:get, path)
      |> then(&Pages.Shim.__retain_connect_params(&1, page.conn))
      |> Pages.new(page.context)
    else
      {:error, :external, path}
    end
  end

  # # #

  defimpl String.Chars do
    def to_string(%Pages.Driver.Conn{conn: %Plug.Conn{status: 200} = conn}),
      do: Phoenix.ConnTest.html_response(conn, 200)
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(driver, _opts) do
      concat(["Pages.Driver.Conn.visit(page, \"", driver.conn.request_path, "\")"])
    end
  end

  # # #

  defp error!(page, msg),
    do: raise(Pages.Error, msg <> "\n\nHTML:\n\n#{Hq.pretty(page)}")

  defp refute_link_method(link) do
    method = link |> Hq.attr("data-method")

    if method do
      raise Pages.Error, "Expected link to have no data-method but was '#{method}'"
    end
  end

  defp assert_link_method(link, expected_method) do
    method = link |> Hq.attr("data-method")

    if method != expected_method do
      raise Pages.Error, "Expected link to have data-method '#{expected_method}' but was '#{method}'"
    end
  end

  defp assert_link_text(link, expected_text) do
    link_text = link |> Hq.text()

    if !String.contains?(link_text, expected_text) do
      raise Pages.Error, "Expected link to have text '#{expected_text}' but was '#{link_text}'"
    end
  end
end
