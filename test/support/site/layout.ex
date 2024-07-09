defmodule Test.Site.Layout do
  use Phoenix.Component

  def render("basic.html", assigns) do
    ~H"""
    <html lang="en">
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end
