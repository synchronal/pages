defmodule Pages.Driver.Conn do
  # @related [drivers](lib/pages/driver.ex)

  @moduledoc """
  A page driver for interacting with Phoenix controllers.
  """

  @behaviour Pages.Driver

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

  def visit(%__MODULE__{} = page, path) do
    page.conn
    |> Pages.Shim.__dispatch(:get, path)
    |> Pages.new()
  end

  defimpl String.Chars do
    def to_string(%Pages.Driver.Conn{conn: %Plug.Conn{status: 200} = conn}),
      do: Phoenix.ConnTest.html_response(conn, 200)
  end
end
