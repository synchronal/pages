defmodule Pages.Driver do
  # @related [conn driver](lib/pages/driver/conn.ex)
  # @related [live view driver](lib/pages/driver/live_view.ex)

  @moduledoc """
  Defines types and behaviours that page drivers must implement.
  """

  alias HtmlQuery, as: Hq

  @type t() ::
          Pages.Driver.Conn.t()
          | Pages.Driver.LiveView.t()

  @doc "Click an element within a page."
  @callback click(Pages.Driver.t(), Pages.http_method(), binary(), Hq.Css.selector()) :: Pages.Driver.t() | no_return()

  @doc "Re-renders the page"
  @callback rerender(Pages.Driver.t()) :: Pages.Driver.t()

  @doc "Submit a form targeted by the given selector."
  @callback submit_form(Pages.Driver.t(), Hq.Css.selector()) :: Pages.Driver.t()

  @doc "Fills in a form with the attributes and submits it."
  @callback submit_form(Pages.Driver.t(), Hq.Css.selector(), atom(), Pages.attrs_t()) :: Pages.Driver.t()

  @doc "Fills in a form with the attributes without submitting it."
  @callback update_form(Pages.Driver.t(), Hq.Css.selector(), atom(), Pages.attrs_t()) :: Pages.Driver.t()

  @doc "Navigate directly to a page."
  @callback visit(Pages.Driver.t(), Path.t()) :: Pages.Driver.t()

  @doc "Target a child component for actions."
  @callback with_child_component(Pages.Driver.t(), child_id :: binary(), (Pages.Driver.t() -> term())) ::
              Pages.Driver.t()

  @optional_callbacks [click: 4, rerender: 1, submit_form: 2, submit_form: 4, update_form: 4, with_child_component: 3]
end
