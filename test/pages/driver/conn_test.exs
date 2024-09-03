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

  describe "submit_form/2" do
    test "raises when no form exists", %{conn: conn} do
      msg = ~r|No form found for selector: #form|

      assert_raise Pages.Error, msg, fn ->
        conn
        |> Pages.visit("/pages/show")
        |> Pages.submit_form("#form")
      end
    end

    test "posts and follows redirects", %{conn: conn} do
      conn
      |> Pages.visit("/pages/form")
      |> Pages.submit_form("#form")
      |> assert_here("pages/show")

      assert_receive {:page_controller, :submit, :ok, params}
      assert Map.keys(params) == ~w[_csrf_token form]

      assert params["form"] == %{
               "string_value" => "initial",
               "select_value" => "initial",
               "bool_value" => "false",
               "radio_value" => "initial"
             }
    end

    test "handles non-redirect error renders", %{conn: conn} do
      conn
      |> Pages.visit("/pages/form")
      |> Pages.update_form("#form", :form, string_value: "")
      |> Pages.submit_form("#form")
      |> assert_here("pages/form")

      assert_receive {:page_controller, :submit, :error, params}
      assert Map.keys(params) == ~w[_csrf_token form]

      assert params["form"] == %{
               "string_value" => "",
               "select_value" => "",
               "bool_value" => "false",
               "radio_value" => nil
             }
    end
  end

  describe "submit_form/4" do
    test "raises when no form exists", %{conn: conn} do
      assert_raise Pages.Error, fn ->
        conn
        |> Pages.visit("/pages/show")
        |> Pages.submit_form("#form", :form, value: "bar")
      end
    end

    test "posts and follows redirects", %{conn: conn} do
      conn
      |> Pages.visit("/pages/form")
      |> Pages.submit_form("#form", :form, string_value: "updated")
      |> assert_here("pages/show")

      assert_receive {:page_controller, :submit, :ok, params}
      assert Map.keys(params) == ~w[_csrf_token form]

      assert params["form"] == %{
               "string_value" => "updated",
               "select_value" => "",
               "bool_value" => "false",
               "radio_value" => nil
             }
    end

    test "handles non-redirect error renders", %{conn: conn} do
      conn
      |> Pages.visit("/pages/form")
      |> Pages.submit_form("#form", :form, string_value: "")
      |> assert_here("pages/form")

      assert_receive {:page_controller, :submit, :error, params}
      assert Map.keys(params) == ~w[_csrf_token form]

      assert params["form"] == %{
               "string_value" => "",
               "select_value" => "",
               "bool_value" => "false",
               "radio_value" => nil
             }
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

    test "updates text inputs on a form", %{conn: conn} do
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

    test "updates select inputs on a form", %{conn: conn} do
      page =
        conn
        |> Pages.visit("/pages/form")
        |> assert_success()

      assert %{_csrf_token: _, form: form_params} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()

      assert form_params == %{
               select_value: "initial",
               string_value: "initial",
               bool_value: "false",
               radio_value: "initial"
             }

      page = page |> Pages.update_form("#form", :form, select_value: "updated")

      assert %{_csrf_token: _, form: form_params} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()

      assert form_params == %{select_value: "updated", bool_value: "false", radio_value: nil}
    end

    test "updates checkbox inputs on a form", %{conn: conn} do
      page =
        conn
        |> Pages.visit("/pages/form")
        |> assert_success()

      assert %{_csrf_token: _, form: form_params} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()

      assert form_params == %{
               select_value: "initial",
               string_value: "initial",
               bool_value: "false",
               radio_value: "initial"
             }

      page = page |> Pages.update_form("#form", :form, bool_value: true)

      assert %{_csrf_token: _, form: form_params} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()

      assert form_params == %{select_value: "", bool_value: "true", radio_value: nil}
    end

    test "updates radio inputs on a form", %{conn: conn} do
      page =
        conn
        |> Pages.visit("/pages/form")
        |> assert_success()

      assert %{_csrf_token: _, form: form_params} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()

      assert form_params == %{
               select_value: "initial",
               string_value: "initial",
               bool_value: "false",
               radio_value: "initial"
             }

      page = page |> Pages.update_form("#form", :form, radio_value: "updated")

      assert %{_csrf_token: _, form: form_params} =
               page
               |> Hq.find("#form")
               |> Hq.form_fields()

      assert form_params == %{radio_value: "updated", bool_value: "false", select_value: ""}
    end
  end
end
