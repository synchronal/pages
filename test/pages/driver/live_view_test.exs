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

  test "handles redirecting from initial mount to a live view", %{conn: conn} do
    page = conn |> Pages.visit("/live/redirect?case=initial-live")
    assert page.__struct__ == Pages.Driver.LiveView

    page
    |> Hq.find!("[test-page-id]")
    |> Hq.attr("test-page-id")
    |> assert_eq("live")
  end

  test "handles redirecting from connected mount to a live view", %{conn: conn} do
    page = conn |> Pages.visit("/live/redirect?case=connected-live")
    assert page.__struct__ == Pages.Driver.LiveView

    page
    |> Hq.find!("[test-page-id]")
    |> Hq.attr("test-page-id")
    |> assert_eq("live")
  end

  test "handles redirecting from initial mount to a controller", %{conn: conn} do
    page = conn |> Pages.visit("/live/redirect?case=initial-dead")
    assert page.__struct__ == Pages.Driver.Conn

    page
    |> Hq.find!("[test-page-id]")
    |> Hq.attr("test-page-id")
    |> assert_eq("pages/show")
  end

  test "handles redirecting from connected mount to a controller", %{conn: conn} do
    page = conn |> Pages.visit("/live/redirect?case=connected-dead")
    assert page.__struct__ == Pages.Driver.Conn

    page
    |> Hq.find!("[test-page-id]")
    |> Hq.attr("test-page-id")
    |> assert_eq("pages/show")
  end
end
