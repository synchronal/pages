defmodule Pages.HtmlTest do
  # @related [subject](lib/pages/html.ex)

  use Test.SimpleCase, async: true

  describe "all" do
    test "finds all matching elements, and returns them as a list of HTML trees" do
      html = """
      <div>
        <p>P1</p>
        <p>P2<p>P2 A</p><p>P2 B</p></p>
        <p>P3</p>
      </div>
      """

      html
      |> Pages.Html.all("p")
      |> assert_eq([
        {"p", [], ["P1"]},
        {"p", [], ["P2", {"p", [], ["P2 A"]}, {"p", [], ["P2 B"]}]},
        {"p", [], ["P2 A"]},
        {"p", [], ["P2 B"]},
        {"p", [], ["P3"]}
      ])

      html
      |> Pages.Html.all("glorp")
      |> assert_eq([])
    end

    test "accepts queries as strings or keyword lists" do
      html = """
      <div>
        <p id="p1" class="para">P1</p>
        <p id="p2" class="para">P2</p>
      </div>
      """

      html
      |> Pages.Html.all("#p2.para")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])

      html
      |> Pages.Html.all("[id=p2][class=para]")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])

      html
      |> Pages.Html.all(id: "p2", class: "para")
      |> assert_eq([{"p", [{"id", "p2"}, {"class", "para"}], ["P2"]}])
    end
  end

  describe "find" do
    test "finds the first matching element, and returns it as an HTML node" do
      html = """
      <div>
        <p>P1</p>
        <p>P2</p>
        <p>P3</p>
      </div>
      """

      html |> Pages.Html.find("p") |> assert_eq({"p", [], ["P1"]})
      html |> Pages.Html.find("glorp") |> assert_eq(nil)
    end
  end

  describe "find!" do
    test "finds first matching element, returning it as an HTML node, and fails if there are 0 or more than 1" do
      html = """
      <p>P1</p>
      <p>P2</p>
      <div>DIV</div>
      """

      html |> Pages.Html.find!("div") |> assert_eq({"div", [], ["DIV"]})
      assert_raise RuntimeError, fn -> html |> Pages.Html.find!("glorp") end
      assert_raise RuntimeError, fn -> html |> Pages.Html.find!("p") end
    end
  end

  describe "attr" do
    @html """
    <div class="profile-list" id="profiles">
      <div class="profile admin" id="alice">
        <div class="name">Alice</div>
      </div>
      <div class="profile" id="billy">
        <div class="name">Billy</div>
      </div>
    </div>
    """

    test "returns the value of an attr from the outermost element of an HTML node" do
      @html |> Pages.Html.find("#alice") |> Pages.Html.attr("class") |> assert_eq("profile admin")
    end

    test "returns nil if the attr does not exist" do
      @html |> Pages.Html.find("#alice") |> Pages.Html.attr("foo") |> assert_eq(nil)
    end

    test "raises if the first argument is a list or HTML tree" do
      assert_raise RuntimeError,
                   """
                   Expected a single HTML node but got:

                   <div class="profile admin" id="alice">
                     <div class="name">
                       Alice
                     </div>
                   </div>
                   <div class="profile" id="billy">
                     <div class="name">
                       Billy
                     </div>
                   </div>

                   Consider using Enum.map(html, &Pages.Html.attr(&1, "id"))
                   """,
                   fn -> @html |> Pages.Html.all(".profile") |> Pages.Html.attr("id") end
    end
  end

  describe "text" do
    @html """
    <div>
      <p>P1</p>
      <p>P2 <span>a span</span></p>
      <p>P3</p>
    </div>
    """

    test "returns the text value of the HTML node" do
      @html |> Pages.Html.find("div") |> Pages.Html.text() |> assert_eq("P1 P2  a span P3")
    end

    test "requires the use of `Enum.map` to get a list" do
      @html |> Pages.Html.all("p") |> Enum.map(&Pages.Html.text/1) |> assert_eq(["P1", "P2  a span", "P3"])
    end

    test "raises if a list or HTML tree is passed in" do
      assert_raise RuntimeError,
                   """
                   Expected a single HTML node but got:

                   <p>
                     P1
                   </p>
                   <p>
                     P2
                     <span>
                       a span
                     </span>
                   </p>
                   <p>
                     P3
                   </p>

                   Consider using Enum.map(html, &Pages.Html.text/1)
                   """,
                   fn -> @html |> Pages.Html.all("p") |> Pages.Html.text() end
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
      {"div", [], ["hi"]} |> Pages.Html.parse() |> assert_eq([{"div", [], ["hi"]}])
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
end
