defmodule Pages.Driver.ConnTest do
  use Test.ConnCase, async: true

  test "gets from a controller", %{conn: conn} do
    conn
    |> Pages.visit("/pages/show")
    |> assert_success()
    |> assert_driver(:conn)
    |> assert_here("pages/show")
  end
end
