defmodule Pages.HtmlTransformer do
  @moduledoc "Functions that transform Floki HTML"

  @spec filter_by_text(Floki.html_tree(), function()) :: list()
  def filter_by_text(html_tree, fun),
    do: Enum.filter(html_tree, &(&1 |> floki_to_text() |> fun.()))

  @spec to_attribute_values(Floki.html_tree(), Pages.Html.attr()) :: list()
  def to_attribute_values(html_tree, attribute_name),
    do: Enum.flat_map(html_tree, &Floki.attribute(&1, Euclid.Atom.to_string(attribute_name)))

  @spec to_text(Floki.html_node()) :: [binary()]
  def to_text(html_node) when is_tuple(html_node),
    do: floki_to_text(html_node)

  @spec to_text(Floki.html_tree()) :: [binary()]
  def to_text(html_tree),
    do: Enum.map(html_tree, &floki_to_text/1)

  # # #

  defp floki_to_text(html_tree),
    do: Floki.text(html_tree, sep: " ") |> String.trim()
end
