defmodule Test.Site.ErrorHtml do
  @moduledoc false

  use Phoenix.Component

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
