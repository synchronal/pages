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

  @spec merge(t(), keyword() | map()) :: {:ok, t()}
  def merge(form, data) do
    data = form.data |> Moar.Map.deep_merge(data)
    {:ok, %{form | data: data}}
  end

  @spec to_post(t()) :: {String.t(), map()}
  def to_post(form) do
    action = Hq.attr(form.form_html, "action")
    {action, form.data}
  end

  @spec update_html(t(), Hq.html()) :: {:ok, binary()}
  def update_html(form, html) do
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
      |> find_and_update_inputs(key, value)
      |> find_and_update_selects(key, value)
    end)
  end

  defp update_value(attrs, value) do
    Enum.map(attrs, fn
      {"value", _} -> {"value", value}
      other -> other
    end)
  end

  defp find_and_update_inputs(html, key, value) do
    Floki.find_and_update(html, "input[name='#{key}']", fn
      {"input", attrs} -> {"input", update_value(attrs, value)}
    end)
  end

  defp find_and_update_selects(html, key, value) do
    Floki.traverse_and_update(html, fn
      {"select", attrs, children} = select ->
        if List.keyfind(attrs, "name", 0) == {"name", key} do
          {"select", attrs, find_and_update_options(children, value)}
        else
          select
        end

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
end
