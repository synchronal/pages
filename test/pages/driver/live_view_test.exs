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

    test "handles navigating from initial mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=initial-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end

    test "handles navigating from connected mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=connected-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end
  end

  describe "handle_params push_navigate" do
    test "handles navigating from initial mount", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=handle-params&do=initial-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/show")
    end

    test "handles navigating from connected mount", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=handle-params&do=connected-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/show")
    end

    test "handles navigating from initial mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=handle-params&do=initial-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end

    test "handles navigating from connected mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/navigate?case=handle-params&do=connected-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end
  end

  describe "handle_params push_patch" do
    test "handles patching from initial mount to self", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/initial-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/patch/render")
    end

    test "handles patching from initial mount to self across routes", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch?case=initial-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/patch/render")
    end

    test "handles patching from initial mount to self with replace", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/initial-live?replace=true")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/patch/render")
    end

    test "handles patching from initial mount to self with replace across routes", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch?case=initial-live&replace=true")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/patch/render")
    end

    @tag :skip
    test "handles patching from connected mount", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/connected-live")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/patch/render")
    end

    @tag :skip
    test "handles patching from connected mount with replace", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/connected-live?replace=true")
      |> assert_success()
      |> assert_driver(:live_view)
      |> assert_here("live/patch/render")
    end

    test "handles patching from initial mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/initial-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end

    test "handles patching from initial mount to a controller with replace", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/initial-dead?replace=true")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end

    test "handles patching from connected mount to a controller", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/initial-dead")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
    end

    test "handles patching from connected mount to a controller with replace", %{conn: conn} do
      conn
      |> Pages.visit("/live/patch/initial-dead?replace=true")
      |> assert_success()
      |> assert_driver(:conn)
      |> assert_here("pages/show")
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

    test "follows push_navigate to live views", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "navigate-button")
      |> assert_here("live/final")
      |> assert_driver(:live_view)
    end

    test "navigates to dead views", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "navigate-dead-link")
      |> assert_here("pages/show")
      |> assert_driver(:conn)
    end

    test "patches to live views", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "patch-live-link")
      |> assert_here("live/show/link")
      |> assert_driver(:live_view)
    end

    @tag :skip
    test "patches to dead views", %{conn: conn} do
      conn
      |> Pages.visit("/live")
      |> Pages.click(test_role: "patch-dead-link")
      |> assert_here("pages/show")
      |> assert_driver(:conn)
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

  describe "submit_form/2" do
    test "handles render changes from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.update_form("#form", :foo, action: "rerender", value: "rerender")
      |> assert_input_value("form", "value-input", "rerender")
      |> Pages.submit_form("#form")
      |> assert_input_value("form", "value-input", "rerendered")
    end

    test "follows navigation from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.update_form("#form", :foo, action: "rerender", value: "navigate")
      |> assert_input_value("form", "value-input", "navigate")
      |> Pages.submit_form("#form")
      |> assert_here("live/show")
    end

    test "follows redirects from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.update_form("#form", :foo, action: "rerender", value: "redirect")
      |> assert_input_value("form", "value-input", "redirect")
      |> Pages.submit_form("#form")
      |> assert_here("pages/show")
    end

    test "raises when the form does not have phx-submit", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> Pages.visit("/live/form")
        |> Pages.submit_form("#form-without-phx-attrs")
      end
    end
  end

  describe "submit_form with schema" do
    test "handles render changes from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> assert_input_value("form", "value-input", nil)
      |> Pages.submit_form("#form", :foo, value: "rerender")
      |> assert_input_value("form", "value-input", "rerendered")
    end

    test "follows navigation from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.submit_form("#form", :foo, value: "navigate")
      |> assert_here("live/show")
    end

    test "follows redirects from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.submit_form("#form", :foo, value: "redirect")
      |> assert_here("pages/show")
    end

    test "raises when the form does not have phx-submit", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> Pages.visit("/live/form")
        |> Pages.submit_form("#form-without-phx-attrs", :foo, value: "bar")
      end
    end
  end

  describe "submit_form without schema" do
    test "handles render changes from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> assert_input_value("form", "value-input", nil)
      |> Pages.submit_form("#form", foo: [value: "rerender"])
      |> assert_input_value("form", "value-input", "rerendered")
    end

    test "follows navigation from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.submit_form("#form", foo: [value: "navigate"])
      |> assert_here("live/show")
    end

    test "follows redirects from phx-submit event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.submit_form("#form", foo: [value: "redirect"])
      |> assert_here("pages/show")
    end

    test "raises when the form does not have phx-submit", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> Pages.visit("/live/form")
        |> Pages.submit_form("#form-without-phx-attrs", foo: [value: "bar"])
      end
    end
  end

  describe "update_form with schema" do
    test "handlers render changes from phx-change event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> assert_input_value("form", "value-input", nil)
      |> Pages.update_form("#form", :foo, action: "rerender", value: "bar")
      |> assert_input_value("form", "value-input", "bar")
    end

    test "follows navigation from phx-change event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.update_form("#form", :foo, action: "navigate")
      |> assert_here("live/show")
    end

    test "follows redirects from phx-change event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.update_form("#form", :foo, action: "redirect")
      |> assert_here("pages/show")
    end

    test "raises when the form does not have phx-change", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> Pages.visit("/live/form")
        |> Pages.update_form("#form-without-phx-attrs", :foo, action: "bar")
      end
    end
  end

  describe "update_form without schema" do
    test "handlers render changes from phx-change event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> assert_input_value("form", "value-input", nil)
      |> Pages.update_form("#form", foo: [action: "rerender", value: "bar"])
      |> assert_input_value("form", "value-input", "bar")
      |> Pages.update_form("#form", foo: %{action: "rerender", value: "baz"})
      |> assert_input_value("form", "value-input", "baz")
    end

    test "follows navigation from phx-change event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.update_form("#form", foo: [action: "navigate"])
      |> assert_here("live/show")
    end

    test "follows redirects from phx-change event handler", %{conn: conn} do
      conn
      |> Pages.visit("/live/form")
      |> Pages.update_form("#form", foo: [action: "redirect"])
      |> assert_here("pages/show")
    end

    test "raises when the form does not have phx-change", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> Pages.visit("/live/form")
        |> Pages.update_form("#form-without-phx-attrs", foo: [action: "bar"])
      end
    end
  end
end
