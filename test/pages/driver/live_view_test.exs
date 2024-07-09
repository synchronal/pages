defmodule Test.Driver.LiveViewTest do
  # @related [subject](lib/pages/driver/live_view.ex)
  use Test.ConnCase, async: true
  alias HtmlQuery, as: Hq

  test "renders from a live view", %{conn: conn} do
    conn
    |> Pages.visit("/live")
    |> assert_success()
    |> assert_driver(:live_view)
    |> assert_here("live/show")
  end

  describe "mount redirect" do
    test "handles redirecting from initial mount to a live view", %{conn: conn} do
      conn
      |> Pages.visit("/live/redirect?case=initial-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/show")
    end

    test "handles redirecting from connected mount to a live view", %{conn: conn} do
      conn
      |> Pages.visit("/live/redirect?case=connected-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/show")
    end

    test "handles redirecting from initial mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/redirect?case=initial-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end

    test "handles redirecting from connected mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/redirect?case=connected-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end
  end

  describe "mount push_navigate" do
    test "handles navigating from initial mount", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=initial-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/show")
    end

    test "handles navigating from connected mount", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=connected-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/show")
    end
  end

  describe "click" do
    test "handles updates to views", %{conn: conn} do
      page = conn |> Pages.visit("/live")
      assert page |> Hq.find!(test_role: "click-count") |> Hq.text() == "0"

      page = page |> Pages.click(test_role: "click-count")
      assert page |> Hq.find!(test_role: "click-count") |> Hq.text() == "1"
    end

    test "follows redirects to controllers", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "redirect-dead-button")
      |> assert_here("pages/show")
      |> assert_driver(:conn)
    end

    test "follows redirects to live views", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "redirect-live-button")
      |> assert_here("live/final")
      |> assert_driver(:live_view)
    end

    test "follows navigations", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "navigate-button")
      |> assert_here("live/final")
      |> assert_driver(:live_view)
    end

    test "follows patches", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "patch-button")
      |> assert_here("live/final")
      |> assert_driver(:live_view)
    end
  end
end
