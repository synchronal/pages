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

  describe "handle_redirect" do
    test "waits for a message to be sent to redirect", %{conn: conn} do
      conn
      |> Pages.visit("/live/redirect?case=manual")
      |> assert_here("live/redirect")
      |> Pages.click(test_role: "trigger-async-redirect")
      |> assert_here("live/redirect")
      |> Pages.handle_redirect()
      |> assert_here("pages/show")
    end
  end

  describe "rerender" do
    defp assert_rerender_content(page, expected) do
      page
      |> Hq.find!(test_role: "content")
      |> Hq.text()
      |> assert_eq(expected, returning: page)
    end

    test "updates the rendered content based on async changes in the live view", %{conn: conn} do
      conn
      |> Pages.visit("/live/rerender")
      |> assert_here("live/rerender")
      |> assert_rerender_content("0")
      |> Pages.rerender()
      |> assert_rerender_content("1")
    end
  end
end
