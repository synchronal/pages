defmodule Pages.Driver.Conn do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix controllers.
  """

  @behaviour Pages.Driver

  alias HtmlQuery, as: Hq

  defstruct conn: nil, private: %{}

  @type t() :: %__MODULE__{
          conn: Plug.Conn.t(),
          private: map()
        }

  def build(%Plug.Conn{} = conn) do
    %__MODULE__{conn: conn}
  end

  # @deprecated "use build/1 instead"
  # def new(%Plug.Conn{state: :unset} = conn),
  #   do:
  #     conn
  #     |> Pages.Shim.__dispatch(:get, conn.request_path, conn.path_params)
  #     |> Pages.new()

  # def new(%Plug.Conn{status: status_code} = conn) when status_code in [301, 302] do
  #   redirect = Phoenix.ConnTest.redirected_to(conn, status_code)
  #   __struct__(conn: conn) |> visit(redirect)
  # end

  # def new(%Plug.Conn{} = conn),
  #   do: __struct__(conn: conn)

  defp pop_private(%__MODULE__{private: private} = session, key) do
    {popped, rest_private} = Map.pop(private, key, %{})
    {popped, %{session | private: rest_private}}
  end

  defp put_private(%__MODULE__{private: private} = session, key, value) do
    updated_private = Map.put(private, key, value)
    %{session | private: updated_private}
  end


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

    href = Hq.attr(link, :href)
    Pages.visit(page.conn, href)
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
    |> build()
  end

  @impl Pages.Driver
  def update_form(%__MODULE__{} = page, selector, form_data, _opts \\ []) do
    form =
      page
      |> Hq.find!(selector)
      |> Pages.HtmlForm.build()

    :ok = Pages.HtmlForm.validate_form_data!(form, form_data)
    active_form = %{selector: selector, form_data: form_data, parsed: form}

    put_private(page, :active_form, active_form)
  end

  @impl Pages.Driver
  def submit_form(%__MODULE__{} = page, selector, attrs, _hidden_attrs) do
    page
    |> update_form(selector, attrs)
    |> submit_active_form()
  end


  defp submit_active_form(%__MODULE__{} = page) do
    {form, page} = pop_private(page, :active_form)
    action = form.parsed["attributes"]["action"]
    method = form.parsed["operative_method"]

    page.conn
    |> Pages.Shim.__dispatch(method, action, form.form_data)
    |> maybe_redirect(page)
  end

  defp maybe_redirect(%{status: 302} = conn, _page) do
    path = Phoenix.ConnTest.redirected_to(conn)
    Pages.visit(conn, path)
  end

  defp maybe_redirect(%{status: _} = conn, page) do
    %{page | conn: conn}
  end



  # # #

  defimpl String.Chars do
    def to_string(%Pages.Driver.Conn{conn: %Plug.Conn{status: 200} = conn}),
      do: Phoenix.ConnTest.html_response(conn, 200)
  end

  # # #

  defp refute_link_method(link) do
    method = link |> Hq.attr("data-method")

    if method do
      raise "Expected link to have no data-method but was '#{method}'"
    end
  end

  defp assert_link_method(link, expected_method) do
    method = link |> Hq.attr("data-method")

    if method != expected_method do
      raise "Expected link to have data-method '#{expected_method}' but was '#{method}'"
    end
  end

  defp assert_link_text(link, expected_text) do
    link_text = link |> Hq.text()

    if !String.contains?(link_text, expected_text) do
      raise "Expected link to have text '#{expected_text}' but was '#{link_text}'"
    end
  end
end
