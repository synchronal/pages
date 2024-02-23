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

  @doc "Click an element within a page. Implementation for `Pages.click/4`."
  @callback click(Pages.Driver.t(), Pages.http_method(), Pages.text_filter() | nil, Hq.Css.selector()) ::
              Pages.result() | no_return()

  @doc "Render a change. Implementation for `Pages.render_change/3`."
  @callback render_change(Pages.Driver.t(), Hq.Css.selector(), Enum.t()) :: Pages.result()

  @doc "Render a file upload. Implementation for `Pages.render_upload/4`."
  @callback render_upload(Pages.Driver.t(), Pages.live_view_upload(), binary(), integer()) :: Pages.result()

  @doc "Render a hook event. Implementation for `Pages.render_hook/3`."
  @callback render_hook(Pages.Driver.t(), binary(), Pages.attrs_t(), keyword()) :: Pages.result()

  @doc "Re-renders the page. Implementation for `Pages.rerender/1`."
  @callback rerender(Pages.Driver.t()) :: Pages.result()

  @doc "Fills in a form targeted by the given selector and submits it. Implementation for `Pages.submit_form/4`."
  @callback submit_form(Pages.Driver.t(), Hq.Css.selector(), Pages.attrs_t(), Pages.attrs_t()) :: Pages.result()

  @doc "Fills in a form with the attributes without submitting it. Implementation for `Pages.update_form/4`."
  @callback update_form(Pages.Driver.t(), Hq.Css.selector(), Pages.attrs_t(), Keyword.t()) :: Pages.result()

  @doc "Navigate directly to a page. Implementation for `Pages.visit/2`."
  @callback visit(Pages.Driver.t(), Path.t()) :: Pages.result()

  @doc "Target a child component for actions. Implementation for `Pages.with_child_component/3`."
  @callback with_child_component(Pages.Driver.t(), child_id :: binary(), (Pages.Driver.t() -> term())) ::
              Pages.Driver.t()

  @optional_callbacks [
    click: 4,
    render_change: 3,
    render_upload: 4,
    render_hook: 4,
    rerender: 1,
    with_child_component: 3
  ]
end
