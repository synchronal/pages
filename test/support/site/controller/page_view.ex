defmodule Test.Site.PageView do
  use Phoenix.Component

  def render("root.html", assigns) do
    ~H"""
    <main test-page-id="pages/root">
      Root content
    </main>
    """
  end

  def render("show.html", assigns) do
    ~H"""
    <main test-page-id="pages/show">
      Show content
    </main>
    """
  end

  def render("form.html", assigns) do
    ~H"""
    <main test-page-id="pages/form">
      <.form id="form" for={@form} action="/pages/form">
        <.input type="text" field={@form[:string_value]} label="String Value" />
        <.input type="select" field={@form[:select_value]} label="Select Value" options={select_value_options()} />
        <.input type="checkbox" field={@form[:bool_value]} label="Check Value" />
        <.input
          type="radio"
          field={@form[:radio_value]}
          value="initial"
          checked={@form[:radio_value].value == :initial}
          label="Initial"
        />
        <.input
          type="radio"
          field={@form[:radio_value]}
          value="updated"
          checked={@form[:radio_value].value == :updated}
          label="Updated"
        />
      </.form>
    </main>
    """
  end

  # # #

  defp select_value_options,
    do: [{"Initial", :initial}, {"Updated", :updated}]

  # # #

  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:errors, :list, default: [])
  attr(:field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]")
  attr(:id, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")
  attr(:name, :any, doc: "Should be nil if field is like `@profile[:email]`")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:required, :boolean, default: false)

  attr(:rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                  multiple pattern placeholder readonly required rows size step))

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
                  radio range search select tel text textarea time url week)
  )

  attr(:value, :any)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:"test-element-type", fn -> "form-field" end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label>
        <input type="hidden" name={@name} value="false" />
        <input type="checkbox" id={@id} name={@name} value="true" checked={@checked} {@rest} />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "radio"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <label>
        <input type="radio" id={@id} name={@name} value={@value} checked={@checked} {@rest} />
        <%= @label %>
      </label>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id} required={@required} value={@label} />
      <select id={@id} name={@name} multiple={@multiple} {@rest}>
        <option value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id} value={@label} />
      <input
        id={@id}
        name={@name}
        required={@required}
        type={@type}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p test-role="error">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  defp label(assigns) do
    ~H"""
    <label for={@for}><%= @value %></label>
    """
  end

  defp translate_error({msg, _opts}),
    do: msg
end
