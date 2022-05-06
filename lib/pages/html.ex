defmodule Pages.Html do
  # @related [test](/test/pages/html_test.exs)

  @moduledoc """
  Some simple HTML query functions, originally intended for unit tests.
  Delegates the hard work to [Floki](https://hex.pm/packages/floki).

  The main query functions are:

  * `all/2`: returns all elements matching the selector
  * `find/2`: returns the first element that matches the selector
  * `find!/2`: like `find/2` but raises if more than one element matches the selector

  Selectors can be a valid CSS selector string, or can be a keyword list. See `Pages.Css` for keyword list syntax.

  The `attr/2` function can be used to extract attr values, and the `text/1` function can be used to extract
  the text of an HTML fragment.

  ## Examples

  Get the value of a selected option:

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> Pages.Html.find(html, "select option[selected]") |> Pages.Html.attr("value")
  "a"
  ```

  Get the text of a selected option, raising if there are more than one:

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> Pages.Html.find!(html, "select option[selected]") |> Pages.Html.text()
  "apples"
  ```

  Get the text of all the options:

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> Pages.Html.all(html, "select option") |> Enum.map(&Pages.Html.text/1)
  ["apples", "bananas"]
  ```

  Use a keyword list as the selector:

  ```elixir
  iex> html = ~s|<div> <a href="/logout" test-role="logout-link">logout</a> </div>|
  iex> Pages.Html.find!(html, test_role: "logout-link") |> Pages.Html.attr("href")
  "/logout"
  ```
  """

  @module_name __MODULE__ |> Module.split() |> Enum.join(".")

  @type attr :: binary() | atom()
  @type html :: binary() | Pages.Driver.t() | Floki.html_tree()
  @type selector :: binary() | keyword() | atom()

  # # #

  @doc """
  Finds all elements in `html` that match `selector`. Returns a
  [Floki HTML tree](https://hexdocs.pm/floki/Floki.html#t:html_tree/0), which is a list of
  [Floki HTML nodes](https://hexdocs.pm/floki/Floki.html#t:html_node/0).

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> Pages.Html.all(html, "option")
  [
    {"option", [{"value", "a"}, {"selected", "selected"}], ["apples"]},
    {"option", [{"value", "b"}], ["bananas"]}
  ]
  ```
  """
  @spec all(html(), selector()) :: Floki.html_tree()
  def all(html, selector), do: html |> parse() |> Floki.find(Pages.Css.selector(selector))

  @doc """
  Finds the first element in `html` that matches `selector`. Returns a
  [Floki HTML node](https://hexdocs.pm/floki/Floki.html#t:html_node/0).

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> Pages.Html.find(html, "select option[selected]")
  {"option", [{"value", "a"}, {"selected", "selected"}], ["apples"]}
  ```
  """
  @spec find(html(), selector()) :: Floki.html_node()
  def find(html, selector), do: all(html, selector) |> List.first()

  @doc """
  Like `find/2` but raises unless exactly one element is found.
  """
  @spec find!(html(), selector()) :: Floki.html_node()
  def find!(html, selector), do: all(html, selector) |> first!()

  # # #

  @doc """
  Returns the value of `attr` from the outermost element of `html`

  ```elixir
  iex> html = ~s|<div> <a href="/logout" test-role="logout-link">logout</a> </div>|
  iex> Pages.Html.find!(html, test_role: "logout-link") |> Pages.Html.attr("href")
  "/logout"
  ```
  """
  @spec attr(html(), attr()) :: binary()
  def attr(nil, _attr), do: nil

  def attr(html, attr) do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.attr(&1, #{inspect(attr)}))")
    |> Floki.attribute(Euclid.Atom.to_string(attr))
    |> List.first()
  end

  @doc """
  Returns the text value of `html`

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> Pages.Html.find!(html, "select option[selected]") |> Pages.Html.text()
  "apples"
  ```
  """
  @spec text(html()) :: binary()
  def text(html) do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.text/1)")
    |> Floki.text(sep: " ")
    |> String.trim()
  end

  # # #

  @doc """
  Returns a map containing the form fields of form `selector` in `html`.

  ```elixir
  iex> html = ~s|<form> <input type="text" name="color" value="green"> <textarea name="desc">A tree</textarea> </form>|
  iex> Pages.Html.form_fields(html, "form")
  %{color: "green", desc: "A tree"}
  ```
  """
  @spec form_fields(html(), selector()) :: map()
  def form_fields(html, selector) do
    %{}
    |> input_values(html, selector)
    |> textarea_values(html, selector)
    |> Euclid.Map.atomize_keys()
  end

  @doc """
  Prints prettified `html` with a label, and then returns the original html.
  """
  @spec inspect_html(html(), binary()) :: html()
  def inspect_html(html, label \\ "INSPECTED HTML") do
    """
    === #{label}:

    #{pretty(html)}
    """
    |> IO.puts()

    html
  end

  @doc """
  Extracts all the meta tags from `html`.

  ```elixir
  iex> html = ~s|<head> <meta charset="utf-8"/> <meta http-equiv="X-UA-Compatible" content="IE=edge"/> </head>|
  iex> Pages.Html.meta_tags(html)
  [%{"charset" => "utf-8"}, %{"content" => "IE=edge", "http-equiv" => "X-UA-Compatible"}]
  ```
  """
  @spec meta_tags(html()) :: [map()]
  def meta_tags(html), do: html |> parse() |> extract_meta_tags()

  @doc """
  Parses and then re-stringifies `html`, increasing the liklihood that two equivalent HTML strings can
  be considered equal.

  ```elixir
  iex> a = ~s|<p id="color">green</p>|
  iex> b = ~s|<p  id = "color" >green</p>|
  iex> a == b
  false
  iex> Pages.Html.normalize(a) == Pages.Html.normalize(b)
  true
  ```
  """
  @spec normalize(html()) :: binary()
  def normalize(html), do: html |> parse() |> Floki.raw_html()

  @doc """
  Parses an HTML fragment using `Floki.parse_fragment!/1`, returning a
  [Floki HTML tree](https://hexdocs.pm/floki/Floki.html#t:html_tree/0).

  `html` can be an HTML string, a Floki HTML tree, a Floki HTML node, or any struct that implements `String.Chars`.
  """
  @spec parse(html()) :: Floki.html_tree()
  def parse(html_string) when is_binary(html_string), do: html_string |> Floki.parse_fragment!()
  def parse(html_tree) when is_list(html_tree), do: html_tree
  def parse({element, attrs, contents}), do: [{element, attrs, contents}]
  def parse(%_{} = struct), do: struct |> implements_protocol!(String.Chars) |> to_string() |> parse()

  @doc """
  Parses an HTML document using `Floki.parse_document!/1`, returning a
  [Floki HTML tree](https://hexdocs.pm/floki/Floki.html#t:html_tree/0).
  """
  @spec parse_doc(binary()) :: Floki.html_tree()
  def parse_doc(html_string), do: html_string |> Floki.parse_document!()

  @doc """
  Pretty-ifies `html` using `Floki.raw_html/2` and its `pretty: true` option.
  """
  @spec pretty(html()) :: binary()
  def pretty(html), do: html |> parse() |> Floki.raw_html(encode: false, pretty: true)

  # # #

  defp attrs_to_map(list, key_attr, value_attr, key_transformer) do
    Map.new(list, fn element ->
      key = Floki.attribute(element, key_attr) |> List.first() |> key_transformer.()

      value =
        if value_attr == :text,
          do: Pages.HtmlTransformer.to_text(element),
          else: Floki.attribute(element, value_attr) |> List.first()

      {key, value}
    end)
  end

  @spec extract_meta_tags(html()) :: [map()]
  defp extract_meta_tags(html) do
    all(html, "meta") |> Enum.map(fn {"meta", attrs, _} -> Map.new(attrs) end)
  end

  # # #

  defp input_values(acc, html, selector) do
    html
    |> all(Pages.Css.selector(selector) <> " input[type=text]")
    |> attrs_to_map("name", "value", &unwrap_input_name/1)
    |> Map.merge(acc, fn _k, a, b -> List.flatten([a, b]) end)
  end

  defp textarea_values(acc, html, selector) do
    html
    |> all(Pages.Css.selector(selector) <> " textarea")
    |> attrs_to_map("name", :text, &unwrap_input_name/1)
    |> Map.merge(acc, fn _k, a, b -> List.flatten([a, b]) end)
  end

  defp unwrap_input_name(input_name) do
    case Regex.run(~r|.*\[(.*)\]|, input_name) do
      [_, unwrapped] when not is_nil(unwrapped) -> unwrapped
      _ -> input_name
    end
  end

  # # #

  # switch to Euclid following merge: https://github.com/geometerio/euclid/pull/6
  defp implements_protocol!(x, protocol) do
    if protocol.impl_for(x) == nil,
      do: raise("Expected #{inspect(x)} to implement protocol #{inspect(protocol)}"),
      else: x
  end

  # # #

  defp first!(html, hint \\ nil)

  defp first!([], _hint), do: raise("Expected a single HTML node but found none")

  defp first!([node], _hint), do: node

  defp first!(html, hint) do
    raise """
    Expected a single HTML node but got:

    #{pretty(html)}
    #{hint}
    """
  end
end
