defmodule Pages.Driver.ConnTest do
  use Test.ConnCase, async: true
  alias HtmlQuery, as: Hq

  test "gets from a controller", %{conn: conn} do
    conn
    |> Pages.visit("/pages/show")
    |> Hq.find!("[test-page-id]")
    |> Hq.attr("test-page-id")
    |> assert_eq("pages/show")
  end
end
