defmodule Pages.Driver.ConnTest do
  use Test.ConnCase, async: true
  alias HtmlQuery, as: Hq

  test "gets from a controller", %{conn: conn} do
    conn
    |> Pages.visit("/pages/show")
    |> assert_success()
    |> assert_driver(:conn)
    |> assert_here("pages/show")
  end

  describe "submit_form" do
    test "raises when no form exists", %{conn: conn} do
      msg = ~r|No form found for selector: #form|

      assert_raise Pages.Error, msg, fn ->
        conn
        |> Pages.visit("/pages/show")
        |> Pages.submit_form("#form")
      end
    end

    test "submits existing values on a form", %{conn: conn} do
      conn
      |> Pages.visit("/pages/form")
      |> Pages.submit_form("#form")
      |> assert_here("pages/show")

      assert_receive {:page_controller, :submit, params}
      assert Map.keys(params) == ~w[_csrf_token form]
      assert params["form"] == %{"string_value" => "initial"}
    end
  end

  describe "update_form" do
    test "raises when no form exists", %{conn: conn} do
      msg = ~r|No form found for selector: #form|

      assert_raise Pages.Error, msg, fn ->
        conn
        |> Pages.visit("/pages/show")
        |> Pages.update_form("#form", :form, string_value: "something")
      end
    end

    test "updates a form", %{conn: conn} do
      page =
        conn
        |> Pages.visit("/pages/form")
        |> assert_success()

      assert %{_csrf_token: _, form: %{string_value: "initial"}} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()

      page = page |> Pages.update_form("#form", :form, string_value: "updated value")

      assert %{_csrf_token: _, form: %{string_value: "updated value"}} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()
    end
  end
end
