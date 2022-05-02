defmodule Pages.Driver do
  # @related [conn driver](lib/pages/driver/conn.ex)
  # @related [live view driver](lib/pages/driver/live_view.ex)

  @moduledoc """
  Defines types and behaviours that page drivers must implement.
  """

  @type t() ::
          %Pages.Driver.Conn{}
          | %Pages.Driver.LiveView{}

  @doc "Click an element within a page."
  @callback click(Pages.Driver.t(), binary(), Pages.Css.selector()) ::
              Pages.Driver.t() | no_return()

  @doc "Submit a form targeted by the given selector."
  @callback submit_form(Pages.Driver.t(), Pages.Css.selector()) :: Pages.Driver.t()

  @doc "Fills in a form with the attributes and submits it."
  @callback submit_form(Pages.Driver.t(), Pages.Css.selector(), atom(), Pages.attrs_t()) ::
              Pages.Driver.t()
  @doc "Fills in a form with the attributes without submitting it."
  @callback update_form(Pages.Driver.t(), Pages.Css.selector(), atom(), Pages.attrs_t()) ::
              Pages.Driver.t()

  @doc "Navigate directly to a page."
  @callback visit(Pages.Driver.t(), Path.t()) :: Pages.Driver.t()

  @optional_callbacks [click: 3, submit_form: 2, submit_form: 4, update_form: 4]
end
