defmodule Test.Driver.LiveViewTest do
  # @related [subject](lib/pages/driver/live_view.ex)
  use Test.ConnCase, async: true

  test "renders from a live view", %{conn: conn} do
    conn
    |> Pages.visit("/live")
    |> assert_success()
    |> assert_driver(:live_view)
    |> assert_here("live")
  end

  describe "mount redirect" do
    test "handles redirecting from initial mount to a live view", %{conn: conn} do
      conn
      |> Pages.visit("/live/redirect?case=initial-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live")
    end

    test "handles redirecting from connected mount to a live view", %{conn: conn} do
      conn
      |> Pages.visit("/live/redirect?case=connected-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live")
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
    test "handles redirecting from initial mount to a live view", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=initial-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live")
    end

    test "handles redirecting from connected mount to a live view", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=connected-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live")
    end
  end
end
