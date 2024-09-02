defmodule Test.Site.PageController do
  use Phoenix.Controller, layouts: [html: {Test.Site.Layout, :basic}]
  use Phoenix.VerifiedRoutes, endpoint: Test.Site.Endpoint, router: Test.Site.Router
  import Phoenix.Component, only: [to_form: 2]

  # # #

  defmodule Data do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:string_value, :string)
      field(:select_value, Ecto.Enum, values: ~w[initial updated]a)
      field(:bool_value, :boolean)
    end

    @required_attrs ~w[string_value]a
    @optional_attrs ~w[bool_value select_value]a

    def changeset(params \\ %{}) do
      %__MODULE__{string_value: "initial", select_value: :initial}
      |> Ecto.Changeset.cast(params, @required_attrs ++ @optional_attrs)
      |> Ecto.Changeset.validate_required(@required_attrs)
    end
  end

  # # # Actions

  def show(conn, _params),
    do: render(conn, :show)

  def form(conn, _params) do
    data = Data.changeset()

    conn
    |> assign(:form, data |> to_form(as: :form))
    |> render(:form)
  end

  def submit(conn, %{"form" => form_params} = params) do
    changeset = Data.changeset(form_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, _} ->
        send(self(), {:page_controller, :submit, :ok, params})
        redirect(conn, to: ~p"/pages/show")

      {:error, changeset} ->
        send(self(), {:page_controller, :submit, :error, params})

        conn
        |> assign(:form, changeset |> to_form(as: :form))
        |> render(:form)
    end
  end
end
