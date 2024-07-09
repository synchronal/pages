defmodule Test.Helpers do
  alias HtmlQuery, as: Hq
  import Moar.Assertions

  def assert_driver(%Pages.Driver.Conn{} = page, :conn), do: page
  def assert_driver(%Pages.Driver.LiveView{} = page, :live_view), do: page

  def assert_here(page, page_id),
    do:
      page
      |> Hq.find!("[test-page-id]")
      |> Hq.attr("test-page-id")
      |> Moar.Assertions.assert_eq(page_id, returning: page)

  def assert_input_value(page, form_id, test_role, expected) do
    page
    |> Hq.find!("##{form_id} input[test-role=#{test_role}]")
    |> Hq.attr("value")
    |> assert_eq(expected, returning: page)
  end

  def assert_success(%Pages.Driver.Conn{conn: %{status: 200}} = page), do: page
  def assert_success(%Pages.Driver.LiveView{} = page), do: page
end
