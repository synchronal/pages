defmodule Pages.Html do
  # @related [test](/test/pages/html_test.exs)

  @moduledoc "Heplful test functions for HTML. Mostly delegates to Floki"

  @type attr :: binary() | atom()
  @type scope :: :all | :first | :first!
  @type html :: binary() | Pages.Driver.t() | Floki.html_tree()
  @type query :: binary() | keyword() | atom()

  @spec attr(html(), attr(), scope(), query()) :: binary() | [binary()]
  def attr(html, attr, scope, query),
    do: html |> find(scope, query, &Pages.HtmlTransformer.to_attribute_values(&1, attr))

  @spec data(html(), attr(), scope(), query()) :: binary() | [binary()]
  def data(html, data_attr, scope, query),
    do: html |> attr("data-#{data_attr}", scope, query)

  @spec text(html(), scope(), query()) :: binary() | [binary()]
  def text(html, scope, query),
    do: html |> find(scope, query, &Pages.HtmlTransformer.to_text/1)

  @spec tid(html(), scope(), query()) :: nil | binary() | [binary()]
  def tid(html, scope, query),
    do: html |> attr("tid", scope, query)

  # # #

  @spec find(html(), scope(), query(), fun()) :: Floki.html_tree()
  def find(html, scope, query, fun \\ &Function.identity/1),
    do:
      html
      |> parse()
      |> Floki.find(Pages.Css.query(query))
      |> fun.()
      |> apply_scope(scope, html, query)

  # # #

  @spec form_fields(html(), query()) :: map()
  def form_fields(html, query) do
    %{}
    |> input_values(html, query)
    |> textarea_values(html, query)
    |> Euclid.Map.atomize_keys()
  end

  defp input_values(acc, html, query) do
    html
    |> find(:all, Pages.Css.query(query) <> " input[type=text]")
    |> attrs_to_map("name", "value", &unwrap_input_name/1)
    |> Map.merge(acc, fn _k, a, b -> List.flatten([a, b]) end)
  end

  defp textarea_values(acc, html, query) do
    html
    |> find(:all, Pages.Css.query(query) <> " textarea")
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
  def parse({element, attrs, contents}), do: {element, attrs, contents}

  def parse(%_{} = struct),
    do: struct |> implements_protocol!(String.Chars) |> to_string() |> parse()

  @spec parse_doc(binary()) :: Floki.html_tree()
  def parse_doc(html_string), do: html_string |> Floki.parse_document!()

  @spec pretty(html()) :: binary()
  def pretty(html), do: html |> parse() |> Floki.raw_html(encode: false, pretty: true)

  # # #

  defp apply_scope(list, :all, _, _), do: list
  defp apply_scope([], :first, _, _), do: nil
  defp apply_scope([first | _rest], :first, _, _), do: first

  defp apply_scope([], :first!, html, query),
    do: raise("Found 0, expected 1\nquery: #{inspect(query)}\nhtml : #{pretty(html)}")

  defp apply_scope([only], :first!, _, _), do: only

  defp apply_scope(list, :first!, html, query),
    do:
      raise("Found #{length(list)}, expected 1\nquery: #{inspect(query)}\nhtml : #{pretty(html)}")

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
    find(html, :all, "meta") |> Enum.map(fn {"meta", attrs, _} -> Map.new(attrs) end)
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
end
