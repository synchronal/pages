defmodule Test.Helpers do
  alias HtmlQuery, as: Hq

  def assert_driver(%Pages.Driver.Conn{} = page, :conn), do: page
  def assert_driver(%Pages.Driver.LiveView{} = page, :live_view), do: page

  def assert_here(page, page_id),
    do:
      page
      |> Hq.find!("[test-page-id]")
      |> Hq.attr("test-page-id")
      |> Moar.Assertions.assert_eq(page_id, returning: page)

  def assert_success(%Pages.Driver.Conn{conn: %{status: 200}} = page), do: page
  def assert_success(%Pages.Driver.LiveView{} = page), do: page
end
