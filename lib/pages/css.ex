defmodule Pages.Css do
  # @related [test](/test/pages/css_test.exs)

  @moduledoc "Constructs CSS selectors via Elixir data structures."

  @type selector() :: binary() | atom() | list()

  @doc ~S"""
  When given a string, returns the string. Otherwise, accepts a keyword list and converts it into a string.

  ## Examples

     iex> Pages.Css.query(test_role: "wheat", class: "math")
     "[test-role='wheat'][class='math']"

     iex> Pages.Css.query(p: [test_role: "wheat", class: "math"])
     "p[test-role='wheat'][class='math']"

     iex> Pages.Css.query([[p: [id: "blue", data_favorite: true]], :div, [class: "class", test_role: "role"]])
     "p[id='blue'][data-favorite] div [class='class'][test-role='role']"

  """
  def query(binary) when is_binary(binary), do: binary
  def query(atom) when is_atom(atom), do: atom |> to_string() |> query()
  def query(list) when is_list(list), do: reduce(list) |> Euclid.String.squish()

  defp reduce(input, result \\ "")
  defp reduce([head | tail], result), do: result <> reduce(head) <> reduce(tail)

  defp reduce({k, v}, result) when is_atom(k),
    do: reduce({k |> to_string() |> Euclid.String.dasherize(), v}, result)

  defp reduce({k, v}, result) when is_list(v), do: "#{result} #{k}#{reduce(v)}"
  defp reduce({_k, false}, result), do: result
  defp reduce({k, true}, result), do: "#{result}[#{k}]"
  defp reduce({k, v}, result), do: "#{result}[#{k}='#{v}']"
  defp reduce(term, result), do: "#{result} #{term} "
end
