defmodule Pages.Html do
  # @related [test](/test/pages/html_test.exs)

  @moduledoc """
  Some simple HTML query functions, originally intended for unit tests.
  Delegates the hard work to [Floki](https://hex.pm/packages/floki).

  The main query functions are:

  * `all`: returns all elements matching the selector
  * `first`: returns the first element that matches the selector
  * `first!`: like `first` but raises if more than one element matches the selector

  Selectors can be a valid CSS selector string, or can be a keyword list. See `Pages.Css` for keyword list syntax.

  The `attr/2` function can be used to extract attr values, and the `text/1` function can be used to extract
  the text of an HTML fragment.

  ## Usage

  Example HTML:

  ```
  <div class="profile-list" id="profiles">
    <div class="profile admin" id="alice">
      <div class="name">Alice</div>
    </div>
    <div class="profile" id="billy">
      <div class="name">Billy</div>
    </div>
  </div>
  ```

  Get Alice's name:

  ```
  iex> Pages.Html.find!(html, "#alice .name") |> Pages.Html.text()
  "Alice"
  ```

  Get the names of all the profiles:

  ```
  iex> Pages.Html.all(html, ".profile .name") |> Enum.map(&Pages.Html.text/1)
  ["Alice", "Billy"]
  ```
  """

  @module_name __MODULE__ |> Module.split() |> Enum.join(".")

  @type attr :: binary() | atom()
  @type html :: binary() | Pages.Driver.t() | Floki.html_tree()
  @type selector :: binary() | keyword() | atom()

  # # #

  @spec all(html(), selector()) :: Floki.html_tree()
  @doc "Finds all elements in `html` that match `selector`."
  def all(html, selector), do: html |> parse() |> Floki.find(Pages.Css.query(selector))

  @spec find(html(), selector()) :: Floki.html_node()
  @doc "Finds the first element in `html` that matches `selector`"
  def find(html, selector), do: all(html, selector) |> List.first()

  @spec find!(html(), selector()) :: Floki.html_node()
  @doc "Like `find/2` but raises unless exactly one element is found"
  def find!(html, selector), do: all(html, selector) |> first!()

  # # #

  @spec attr(html(), attr()) :: [binary()]
  @doc "Returns the value of an attr from the outermost element of an HTML node"
  def attr(nil, _attr), do: nil

  def attr(html, attr) do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.attr(&1, #{inspect(attr)}))")
    |> Floki.attribute(Euclid.Atom.to_string(attr))
    |> List.first()
  end

  @spec text(html()) :: binary()
  @doc "Returns the text value of `html`"
  def text(html) do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.text/1)")
    |> Floki.text(sep: " ")
    |> String.trim()
  end

  # # #

  @spec form_fields(html(), selector()) :: map()
  def form_fields(html, selector) do
    %{}
    |> input_values(html, selector)
    |> textarea_values(html, selector)
    |> Euclid.Map.atomize_keys()
  end

  defp input_values(acc, html, selector) do
    html
    |> all(Pages.Css.query(selector) <> " input[type=text]")
    |> attrs_to_map("name", "value", &unwrap_input_name/1)
    |> Map.merge(acc, fn _k, a, b -> List.flatten([a, b]) end)
  end

  defp textarea_values(acc, html, selector) do
    html
    |> all(Pages.Css.query(selector) <> " textarea")
    |> attrs_to_map("name", :text, &unwrap_input_name/1)
    |> Map.merge(acc, fn _k, a, b -> List.flatten([a, b]) end)
  end

  @spec inspect_html(html(), binary()) :: html()
  def inspect_html(html, label \\ "INSPECTED HTML") do
    """
    === #{label}:

    #{pretty(html)}
    """
    |> IO.puts()

    html
  end

  @spec meta_tags(html()) :: [map()]
  def meta_tags(html), do: html |> parse() |> extract_meta_tags()

  @spec normalize(html()) :: binary()
  def normalize(html), do: html |> parse() |> Floki.raw_html()

  @spec parse(html()) :: Floki.html_tree()
  def parse(html_string) when is_binary(html_string), do: html_string |> Floki.parse_fragment!()
  def parse(html_tree) when is_list(html_tree), do: html_tree
  def parse({element, attrs, contents}), do: [{element, attrs, contents}]
  def parse(%_{} = struct), do: struct |> implements_protocol!(String.Chars) |> to_string() |> parse()

  @spec parse_doc(binary()) :: Floki.html_tree()
  def parse_doc(html_string), do: html_string |> Floki.parse_document!()

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

  defp unwrap_input_name(input_name) do
    case Regex.run(~r|.*\[(.*)\]|, input_name) do
      [_, unwrapped] when not is_nil(unwrapped) -> unwrapped
      _ -> input_name
    end
  end

  # switch to Euclid following merge: https://github.com/geometerio/euclid/pull/6
  defp implements_protocol!(x, protocol) do
    if protocol.impl_for(x) == nil,
      do: raise("Expected #{inspect(x)} to implement protocol #{inspect(protocol)}"),
      else: x
  end

  # # #

  defp first!(html, hint \\ nil)

  defp first!([node], _hint), do: node

  defp first!(html, hint) do
    raise """
    Expected a single HTML node but got:

    #{pretty(html)}
    #{hint}
    """
  end
end
