defmodule Test.ConnCase do
  @moduledoc """
  Initializes a Plug.Conn for tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint Test.Site.Endpoint

      import Moar.Assertions
      import Phoenix.ConnTest
      import Plug.Conn
      import Test.Helpers

      setup [:setup_tracer]
    end
  end

  setup _tags do
    conn = Phoenix.ConnTest.build_conn()
    [conn: conn]
  end
end
