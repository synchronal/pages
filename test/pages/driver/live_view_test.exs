defmodule Test.Driver.LiveViewTest do
  use Test.ConnCase, async: true
  alias HtmlQuery, as: Hq

  test "renders from a live view", %{conn: conn} do
    page = conn |> Pages.visit("/live")
    assert page.__struct__ == Pages.Driver.LiveView

    page
    |> Hq.find!("[test-page-id]")
    |> Hq.attr("test-page-id")
    |> assert_eq("live")
  end
end
