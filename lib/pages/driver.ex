defmodule Pages.Driver do
  # @related [conn driver](lib/pages/driver/conn.ex)
  # @related [live view driver](lib/pages/driver/live_view.ex)

  @moduledoc """
  Defines types and behaviours that page drivers must implement.
  """

  alias HtmlQuery, as: Hq

  @enforce_keys ~w[driver state]a
  defstruct ~w[driver state]a

  def new(driver, state) do
    __struct__(driver: driver, state: state)
  end

  @type t() :: %__MODULE__{
          driver: module(),
          state: state_t()
        }

  @type state_t() :: term()

  @callback match?(any()) :: boolean()
  @callback new(any()) :: {:ok, state_t()} | :error

  @doc "Click an element within a page. Implementation for `Pages.click/4`."
  @callback click(Pages.Driver.t(), Pages.http_method(), Pages.text_filter() | nil, Hq.Css.selector()) ::
              state_t() | t() | no_return()

  @doc "Wait for a server-issued redirect. Implementation for `Pages.handle_redirect/1`."
  @callback handle_redirect(Pages.Driver.t()) :: state_t() | t()

  @doc "Render a change. Implementation for `Pages.render_change/3`."
  @callback render_change(Pages.Driver.t(), Hq.Css.selector(), Enum.t()) :: state_t() | t()

  @doc "Render a file upload. Implementation for `Pages.render_upload/4`."
  @callback render_upload(Pages.Driver.t(), Pages.live_view_upload(), binary(), integer()) :: state_t() | t()

  @doc "Render a hook event. Implementation for `Pages.render_hook/3`."
  @callback render_hook(Pages.Driver.t(), binary(), Pages.attrs_t(), keyword()) :: state_t() | t()

  @doc "Re-renders the page. Implementation for `Pages.rerender/1`."
  @callback rerender(Pages.Driver.t()) :: state_t() | t()

  @doc "Submit a form targeted by the given selector. Implementation for `Pages.submit_form/2`."
  @callback submit_form(Pages.Driver.t(), Hq.Css.selector()) :: state_t() | t()

  @doc "Submit a form targeted by the given selector. Implementation for `Pages.submit_form/3`."
  @callback submit_form(
              Pages.Driver.t(),
              Hq.Css.selector(),
              attrs :: Pages.attrs_t(),
              hidden_attrs :: Pages.attrs_t()
            ) ::
              state_t() | t()

  @doc "Fills in a form with the attributes and submits it. Implementation for `Pages.submit_form/5`."
  @callback submit_form(
              Pages.Driver.t(),
              Hq.Css.selector(),
              schema :: atom(),
              attrs :: Pages.attrs_t(),
              hidden_attrs :: Pages.attrs_t()
            ) ::
              state_t() | t()

  @doc """
  Fills in a form with the attributes without submitting it. Implementation for `Pages.update_form/5`.

  When updating a form built using `Phoenix.Component.to_form/2` with the `:as` option, one may use
  the `name` prefix of the form as the `:schema` atom.
  """
  @callback update_form(
              Pages.Driver.t(),
              Hq.Css.selector(),
              schema :: atom(),
              attrs :: Pages.attrs_t(),
              opts :: Keyword.t()
            ) :: state_t() | t()

  @doc """
  Fills in a form with the attributes without submitting it. Implementation for `Pages.update_form/4`.

  When interactive with forms backed by multiple changesets, or forms not backed by any changesets,
  one may choose to pass custon nested maps or keywords matching the structure of the params to be
  received in a controller or live view.
  """
  @callback update_form(
              Pages.Driver.t(),
              Hq.Css.selector(),
              attrs :: Pages.attrs_t(),
              opts :: Keyword.t()
            ) :: state_t() | t()

  @doc "Navigate directly to a page. Implementation for `Pages.visit/2`."
  @callback visit(Pages.Driver.t(), Path.t()) :: state_t() | t()

  @doc "Target a child component for actions. Implementation for `Pages.with_child_component/3`."
  @callback with_child_component(Pages.Driver.t(), child_id :: binary(), (Pages.Driver.t() -> term())) ::
              state_t() | t()

  @optional_callbacks [
    click: 4,
    handle_redirect: 1,
    render_change: 3,
    render_upload: 4,
    render_hook: 4,
    rerender: 1,
    submit_form: 2,
    submit_form: 4,
    submit_form: 5,
    update_form: 4,
    update_form: 5,
    with_child_component: 3
  ]

  defimpl String.Chars do
    def to_string(%Pages.Driver{state: state}),
      do: Kernel.to_string(state)
  end
end
