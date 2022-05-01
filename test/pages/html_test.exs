defmodule Pages.HtmlTest do
  # @related [subject](lib/pages/html.ex)

  use Test.SimpleCase, async: true

  doctest Pages.Html

  describe "attr" do
    test "returns the values of the given attribute" do
      html = """
      <div class="baz" id="foo">foo</div>
      <div class="baz" id="bar">bar</div>
      """

      html |> Pages.Html.attr("id", :all, :*) |> assert_eq(["foo", "bar"])
      html |> Pages.Html.attr("class", :all, :*) |> assert_eq(["baz", "baz"])
    end

    test "only gets attrs from elements that match the query (and specifically, not their children)" do
      """
      <div class="exclude" id="div1">
        <p class="include" id="p1">
          <span class="exclude" id="span1"></span>
        </p>
      </div>
      """
      |> Pages.Html.attr("id", :all, class: "include")
      |> assert_eq(["p1"])
    end
  end

  describe "data" do
    test "returns the values of the data attributes" do
      html = """
      <div data-foo="foo1" data-bar="bar1">1</div>
      <div data-foo="foo2" data-bar="bar2">2</div>
      """

      html |> Pages.Html.data("foo", :all, :*) |> assert_eq(["foo1", "foo2"])
      html |> Pages.Html.data("foo", :first, :*) |> assert_eq("foo1")
    end
  end

  describe "find" do
    test "with :all, finds all matching elements" do
      html = """
      <div>
        <p>P1</p>
        <p>P2<p>P2 A</p><p>P2 B</p></p>
        <p>P3</p>
      </div>
      """

      html
      |> Pages.Html.find(:all, "p")
      |> assert_eq([
        {"p", [], ["P1"]},
        {"p", [], ["P2", {"p", [], ["P2 A"]}, {"p", [], ["P2 B"]}]},
        {"p", [], ["P2 A"]},
        {"p", [], ["P2 B"]},
        {"p", [], ["P3"]}
      ])

      html |> Pages.Html.find(:all, "glorp") |> assert_eq([])
    end

    test "with :first, finds first matching element" do
      html = """
      <div>
        <p>P1</p>
        <p>P2</p>
        <p>P3</p>
      </div>
      """

      html |> Pages.Html.find(:first, "p") |> assert_eq({"p", [], ["P1"]})
      html |> Pages.Html.find(:first, "glorp") |> assert_eq(nil)
    end

    test "with :first!, finds first matching element and fails if there are 0 or more than 1" do
      html = """
      <p>P1</p>
      <p>P2</p>
      <div>DIV</div>
      """

      html |> Pages.Html.find(:first!, "div") |> assert_eq({"div", [], ["DIV"]})
      assert_raise RuntimeError, fn -> html |> Pages.Html.find(:first!, "glorp") end
      assert_raise RuntimeError, fn -> html |> Pages.Html.find(:first!, "p") end
    end

    test "query can be a string or a keyword list" do
      html = """
      <div>
        <p id="p1" class="para">P1</p>
        <p id="p2" class="para">P2</p>
      </div>
      """

      html
      |> Pages.Html.find(:all, "[id=p2][class=para]")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])

      html
      |> Pages.Html.find(:all, id: "p2", class: "para")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])
    end

    test "takes a transformer function" do
      html = """
      <div>
        <p>hello</p>
        <p>bob</p>
      </div>
      """

      html
      |> Pages.Html.find(:all, :p, &Enum.map(&1, fn {"p", [], [text]} -> String.upcase(text) end))
      |> assert_eq(["HELLO", "BOB"])
    end
  end

  describe "form_fields" do
    test "returns all the form fields as a name -> value map" do
      html = """
      <form test-role="test-form">
        <input type="text" name="person[name]" value="alice">
        <input type="text" name="person[age]" value="100">
        <textarea name="person[about]">Alice is 100</textarea>
      </form>
      """

      Pages.Html.form_fields(html, test_role: "test-form")
      |> assert_eq(%{name: "alice", age: "100", about: "Alice is 100"})
    end
  end

  describe "meta_tags" do
    test "returns the meta tags" do
      html = """
      <html lang="en">
        <head>
          <meta charset="utf-8"/>
          <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <meta charset="UTF-8" content="ZRgfTSIXKWoqAW8qYAoqFDMIEhNTBnZO-wWymfn2aM6RWXmVUBGi4r3c" csrf-param="_csrf_token" method-param="_method" name="csrf-token"/>

          <title>Title</title>
          <link phx-track-static="phx-track-static" rel="stylesheet" href="/css/app.css"/>
          <script defer="defer" phx-track-static="phx-track-static" type="text/javascript" src="/js/app.js"></script>
        </head>
        <body>body</body>
      </html>
      """

      expected = [
        %{"charset" => "utf-8"},
        %{"content" => "IE=edge", "http-equiv" => "X-UA-Compatible"},
        %{"content" => "width=device-width, initial-scale=1.0", "name" => "viewport"},
        %{
          "charset" => "UTF-8",
          "content" => "ZRgfTSIXKWoqAW8qYAoqFDMIEhNTBnZO-wWymfn2aM6RWXmVUBGi4r3c",
          "csrf-param" => "_csrf_token",
          "method-param" => "_method",
          "name" => "csrf-token"
        }
      ]

      html |> Pages.Html.meta_tags() |> assert_eq(expected, ignore_order: true)
    end
  end

  describe "parse" do
    test "can parse a string" do
      "<div>hi</div>" |> Pages.Html.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "when given a list, assumes it is an already-parsed floki html tree" do
      [{"div", [], ["hi"]}] |> Pages.Html.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "when given a threeple, assumes it is a floki element" do
      {"div", [], ["hi"]} |> Pages.Html.parse() |> assert_eq({"div", [], ["hi"]})
    end

    test "can parse any struct that implements String.Chars" do
      %Test.Etc.TestDiv{contents: "hi"} |> Pages.Html.parse() |> assert_eq([{"div", [], ["hi"]}])
    end

    test "can parse a Test.Page struct because it implements String.Chars" do
      %Pages.Driver.LiveView{rendered: "<div>hi</div>"}
      |> Pages.Html.parse()
      |> assert_eq([{"div", [], ["hi"]}])
    end

    defmodule FooStruct do
      defstruct [:foo]
    end

    test "cannot parse structs that don't implement String.Chars" do
      assert_raise RuntimeError,
                   "Expected %Pages.HtmlTest.FooStruct{foo: 1} to implement protocol String.Chars",
                   fn ->
                     %FooStruct{foo: 1} |> Pages.Html.parse()
                   end
    end
  end

  describe "pretty" do
    test "pretty-prints HTML" do
      """
      <div    id="foo"><p>some paragraph
      </p>
           <span>span!   </span>
           </div>
      """
      |> Pages.Html.pretty()
      |> assert_eq("""
      <div id="foo">
        <p>
          some paragraph
        </p>
        <span>
          span!
        </span>
      </div>
      """)
    end
  end

  describe "text" do
    test "extracts text" do
      """
      <p>Text of the first paragraph</p>
      <span>Here is a span</span>
      <p>Text of the second paragraph, <span>with an embedded span</span></p>
      """
      |> Pages.Html.text(:all, "p")
      |> assert_eq([
        "Text of the first paragraph",
        "Text of the second paragraph,  with an embedded span"
      ])
    end
  end

  describe "tids" do
    test "finds tids" do
      """
      <p class="active" tid="alice">Alice</p>
      <p class="inactive" tid="billy">Billy</p>
      <p class="active" tid="cindy">Cindy</p>
      """
      |> Pages.Html.tid(:all, "p[class=active]")
      |> assert_eq(~w[alice cindy])
    end
  end
end
