defmodule Pages.CssTest do
  # @related [subject](/lib/pages/css.ex)

  use Test.SimpleCase, async: true

  doctest Pages.Css

  describe "query" do
    test "when given a string, returns the string" do
      Pages.Css.query("p[id=abc]")
      |> assert_eq("p[id=abc]")
    end

    test "when given an atom, stringifies it" do
      Pages.Css.query(:div)
      |> assert_eq("div")
    end

    test "when given a list, builds a css selector" do
      Pages.Css.query(id: "blue", class: "color")
      |> assert_eq("[id='blue'][class='color']")

      Pages.Css.query(p: [id: "blue", class: "color"])
      |> assert_eq("p[id='blue'][class='color']")
    end

    test "when given lists, builds multiple css selectors" do
      Pages.Css.query([[id: "blue", class: "color"], [id: "red", class: "color"]])
      |> assert_eq("[id='blue'][class='color'] [id='red'][class='color']")

      Pages.Css.query([[p: [id: "blue", class: "color"]], div: [id: "red", class: "color"]])
      |> assert_eq("p[id='blue'][class='color'] div[id='red'][class='color']")
    end

    test "converts underscores to dashes in attribute names" do
      Pages.Css.query(test_role: "glorp")
      |> assert_eq("[test-role='glorp']")
    end

    test "when value is 'true', include only the key; when 'false', do not render it at all" do
      Pages.Css.query(id: "blue", data_favorite: true, role: false)
      |> assert_eq("[id='blue'][data-favorite]")
    end

    test "all together now" do
      Pages.Css.query([
        [p: [id: "blue", data_favorite: true]],
        :div,
        [class: "class", test_role: "role"]
      ])
      |> assert_eq("p[id='blue'][data-favorite] div [class='class'][test-role='role']")
    end
  end
end
