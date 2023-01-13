defmodule Pages.Driver.Conn do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix controllers.
  """

  @behaviour Pages.Driver

  alias HtmlQuery, as: Hq

  defstruct ~w[conn]a

  @type t() :: %__MODULE__{
          conn: Plug.Conn.t()
        }

  def new(%Plug.Conn{state: :unset} = conn),
    do:
      conn
      |> Pages.Shim.__dispatch(:get, conn.request_path, conn.path_params)
      |> Pages.new()

  def new(%Plug.Conn{status: 302} = conn) do
    redirect = Phoenix.ConnTest.redirected_to(conn)
    __struct__(conn: conn) |> visit(redirect)
  end

  def new(%Plug.Conn{} = conn),
    do: __struct__(conn: conn)

  # # #

  @doc "Simulates clicking on an element at `selector` with title `title`."
  @spec click(Pages.Driver.t(), Pages.http_method(), Pages.text_filter() | nil, Hq.Css.selector()) :: Pages.Driver.t()
  @impl Pages.Driver
  def click(page, :get, maybe_title, selector) do
    link = page |> Hq.find!(selector)
    refute_link_method(link)

    if title = maybe_title do
      assert_link_text(link, title)
    end

    page.conn
    |> Pages.Shim.__dispatch(:get, Hq.attr(link, :href))
    |> Pages.new()
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
    |> Pages.new()
  end

  @impl Pages.Driver
  def visit(%__MODULE__{} = page, path) do
    page.conn
    |> Pages.Shim.__dispatch(:get, path)
    |> Pages.new()
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
