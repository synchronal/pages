defmodule Test.ConnCase do
  @moduledoc """
  The simplest test case template
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint Test.Site.Endpoint

      import Moar.Assertions
      import Phoenix.ConnTest
      import Plug.Conn
      import Test.Helpers
    end
  end

  setup _tags do
    conn = Phoenix.ConnTest.build_conn()
    [conn: conn]
  end
end
