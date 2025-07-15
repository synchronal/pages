defmodule Pages.Form do
  @moduledoc false

  # Form parsing an manipulation for drivers that do not implement change tracking natively,
  # for instance when using Phoenix.ConnTest. This module takes HTML and applies form field
  # updates by assigning to the `value` attributes of input fields.

  alias HtmlQuery, as: Hq

  @type t() :: %__MODULE__{}

  defstruct ~w[
    errors
    data
    form_html
    id
    selector
  ]a

  @spec build(Hq.html(), Hq.Css.selector()) :: {:ok, t()} | {:error, String.t()}
  def build(html, selector) do
    form = html |> new(selector)

    if Enum.any?(form.errors),
      do: {:error, Enum.join(form.errors, "\n\n")},
      else: {:ok, form}
  end

  @spec set(t(), keyword() | map()) :: {:ok, t()}
  def set(form, data) do
    {:ok, %{form | data: data}}
  end

  @spec to_post(t()) :: {String.t(), map()}
  def to_post(form) do
    action = Hq.attr(form.form_html, "action")
    {action, form.data}
  end

  @spec update_html(t(), Hq.html()) :: {:ok, binary()}
  def update_html(form, html) do
    form_inputs = flatten_form_data(form.data)
    form_html = update_form_html(form.form_html, form_inputs)

    html =
      html
      |> Hq.parse()
      |> Floki.traverse_and_update(fn
        {"form", attrs, _children} = f ->
          if current_id?(attrs, form.id) do
            form_html
          else
            f
          end

        other ->
          other
      end)

    {:ok, Floki.raw_html(html)}
  end

  # # #

  defp current_id?(attrs, id) do
    Enum.find_value(attrs, fn
      {"id", ^id} -> true
      _ -> false
    end)
  end

  defp flatten_form_data(data) do
    data
    |> Enum.reduce(%{}, fn
      {key, values}, acc when is_map(values) or is_list(values) ->
        Enum.reduce(values, acc, fn {inner_key, value}, acc ->
          key = Phoenix.HTML.Form.input_name(key, inner_key)
          Map.put(acc, key, value)
        end)

      {key, value}, acc ->
        Map.put(acc, to_string(key), value)
    end)
  end

  defp new(html, selector) do
    form = Hq.find(html, selector)

    if form do
      id = form |> Hq.attr("id")
      fields = Hq.form_fields(form)
      __struct__(selector: selector, id: id, errors: [], data: fields, form_html: form)
    else
      errors =
        [
          """
          No form found for selector: #{Hq.Css.selector(selector)}
          """
        ]

      __struct__(selector: selector, errors: errors)
    end
  end

  defp update_form_html(html, inputs) do
    html
    |> Hq.parse()
    |> Floki.traverse_and_update(fn
      {"input", attrs, children} = input ->
        {"type", type} = List.keyfind(attrs, "type", 0)

        if type == "hidden",
          do: input,
          else: {"input", update_value(attrs, type, inputs), children}

      {"select", attrs, children} ->
        {"name", name} = List.keyfind(attrs, "name", 0) || {"name", nil}
        value = Map.get(inputs, name)

        {"select", attrs, find_and_update_options(children, value)}

      other ->
        other
    end)
  end

  defp find_and_update_options(options, value) do
    Floki.traverse_and_update(options, fn
      {"option", attrs, children} ->
        attrs =
          attrs
          |> List.keydelete("selected", 0)
          |> then(&maybe_select(&1, value, children))

        {"option", attrs, children}

      other ->
        other
    end)
  end

  defp maybe_select(attrs, value, children) do
    cond do
      List.keyfind(attrs, "value", 0) == {"value", value} ->
        [{"selected", "selected"} | attrs]

      Enum.member?(children, value) ->
        [{"selected", "selected"} | attrs]

      true ->
        attrs
    end
  end

  @text_input_types ~w[date email number password search tel text textarea url]
  defp update_value(attrs, type, inputs) when type in @text_input_types do
    {"name", name} = List.keyfind(attrs, "name", 0) || {"name", nil}
    value = Map.get(inputs, name)

    if value,
      do: List.keyreplace(attrs, "value", 0, {"value", value}),
      else: List.keydelete(attrs, "value", 0)
  end

  defp update_value(attrs, "checkbox", inputs) do
    {"name", name} = List.keyfind(attrs, "name", 0) || {"name", nil}
    {"value", field_value} = List.keyfind(attrs, "value", 0)

    checked? = List.keymember?(attrs, "checked", 0)
    value = Map.get(inputs, name) |> to_string()

    cond do
      checked? && field_value == value -> attrs
      field_value == value -> [{"checked", "checked"} | attrs]
      true -> List.keydelete(attrs, "checked", 0)
    end
  end

  defp update_value(attrs, "radio", inputs) do
    {"name", name} = List.keyfind(attrs, "name", 0) || {"name", nil}
    {"value", field_value} = List.keyfind(attrs, "value", 0)

    checked? = List.keymember?(attrs, "checked", 0)
    value = Map.get(inputs, name) |> to_string()

    cond do
      checked? && field_value == value -> attrs
      field_value == value -> [{"checked", "checked"} | attrs]
      true -> List.keydelete(attrs, "checked", 0)
    end
  end
end
