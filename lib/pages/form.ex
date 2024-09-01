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

  @spec apply(t(), Hq.html()) :: {:ok, binary()}
  def apply(form, html) do
    form_html = form.data |> Enum.reduce(form.form_html, &update_input/2)

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

  @spec to_post(t()) :: {String.t(), map()}
  def to_post(form) do
    action = Hq.attr(form.form_html, "action")
    {action, form.data}
  end

  @spec update(t(), atom(), keyword() | map()) :: {:ok, t()}
  def update(form, schema, data) do
    values = %{schema => Moar.Map.deep_atomize_keys(data)}
    data = form.data |> Moar.Map.deep_merge(values)
    {:ok, %{form | data: data}}
  end

  # # #

  defp current_id?(attrs, id) do
    Enum.find_value(attrs, fn
      {"id", ^id} -> true
      _ -> false
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

  defp update_input({key, value}, html) when is_binary(value) do
    html
    |> Hq.parse()
    |> Floki.find_and_update("input[name='#{key}']", fn
      {"input", attrs} -> {"input", update_value(attrs, value)}
    end)
  end

  defp update_input({key, values}, html) when is_map(values) do
    html = html |> Hq.parse()

    values
    |> Enum.reduce(html, fn {inner_key, value}, html ->
      key = Phoenix.HTML.Form.input_name(key, inner_key)

      html
      |> Floki.find_and_update("input[name='#{key}']", fn
        {"input", attrs} -> {"input", update_value(attrs, value)}
      end)
    end)
  end

  defp update_value(attrs, value) do
    Enum.map(attrs, fn
      {"value", _} -> {"value", value}
      other -> other
    end)
  end
end
