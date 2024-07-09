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
end
