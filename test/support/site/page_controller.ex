defmodule Test.Site.PageController do
  use Phoenix.Controller, layouts: [html: {Test.Site.Layout, :basic}]

  def root(conn, _params), do: render(conn, :root)
  def show(conn, _params), do: render(conn, :show)
end
