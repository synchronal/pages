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
      </.form>
    </main>
    """
  end

  # # #

  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:debounce, :boolean, default: true, doc: "when `true`, uses the value of `debounce_ms`")
  attr(:debounce_ms, :integer, default: 300)
  attr(:description, :string, default: nil)
  attr(:direction, :atom, values: [:column, :row], default: :column, doc: "for radio-list")
  attr(:errors, :list, default: [])
  attr(:field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]")
  attr(:id, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")
  attr(:name, :any, doc: "Should be nil if field is like `@profile[:email]`")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:required, :boolean, default: false)

  attr(:type, :string,
    default: "text",
    values: ~w[checkbox color date datetime-local email file hidden month number password
                range radio radio-list search select static tel text textarea time url week]
  )

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:"test-element-type", fn -> "form-field" end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label description={@description} for={@id} value={@label} />
      <input
        id={@id}
        name={@name}
        required={@required}
        type={@type}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      />
      <.error :for={msg <- @errors} test-field={@name} test-role="form-error"><%= msg %></.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p test-role="error" {@rest}>
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
