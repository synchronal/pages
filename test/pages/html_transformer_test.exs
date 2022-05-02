defmodule Pages.HtmlTransformerTest do
  # @related [subject](lib/pages/html_transformer.ex)

  use Test.SimpleCase
  alias Pages.HtmlTransformer

  doctest Pages.HtmlTransformer

  describe "filter_by_text" do
    test "filters the results by a function that accepts the text contents of each item" do
      [
        {"p", [], ["Text of the first paragraph"]},
        {"span", [], ["Here is a span"]},
        {"p", [], ["Text of the second paragraph, ", {"span", [], ["with an embedded span"]}]}
      ]
      |> HtmlTransformer.filter_by_text(&(&1 =~ "paragraph"))
      |> assert_eq([
        {"p", [], ["Text of the first paragraph"]},
        {"p", [], ["Text of the second paragraph, ", {"span", [], ["with an embedded span"]}]}
      ])
    end
  end

  describe "to_attribute_values" do
    test "returns a list of the values of the given attribute" do
      [
        {"div", [{"class", "baz"}, {"id", "foo"}], ["foo!"]},
        {"div", [{"class", "baz"}, {"id", "bar"}], ["bar!"]}
      ]
      |> HtmlTransformer.to_attribute_values("id")
      |> assert_eq(["foo", "bar"])
    end
  end

  describe "to_text" do
    test "converts a floki html tree to a list of binaries" do
      [
        {"p", [], ["Text of the first paragraph"]},
        {"span", [], ["Here is a span"]},
        {"p", [], ["Text of the second paragraph, ", {"span", [], ["with an embedded span"]}]}
      ]
      |> HtmlTransformer.to_text()
      |> assert_eq([
        "Text of the first paragraph",
        "Here is a span",
        "Text of the second paragraph,  with an embedded span"
      ])
    end
  end
end
