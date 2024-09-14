defmodule Test.Helpers do
  import ExUnit.Assertions
  import Moar.Assertions

  alias HtmlQuery, as: Hq
  alias Pages.Driver.Conn
  alias Pages.Driver.LiveView
  require ExUnit.Callbacks

  def assert_driver(%Pages.Driver{driver: Conn} = page, :conn), do: page
  def assert_driver(%Pages.Driver{driver: LiveView} = page, :live_view), do: page

  def assert_driver(page, expected) do
    flunk("""
    Expected driver to be a #{inspect(expected)}

    Found:

    #{inspect(page)}
    """)
  end

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

  def assert_success(%Pages.Driver{driver: Conn, state: %{conn: %{status: 200}}} = page), do: page
  def assert_success(%Pages.Driver{driver: LiveView} = page), do: page

  def assert_success(page) do
    flunk("""
    Expected page to successfully load!

    Found:

    #{inspect(page)}
    """)
  end

  if Test.Versions.otp() |> Version.compare("27.0.0") == :lt do
    def setup_tracer(_ctx), do: :ok
  else
    def setup_tracer(ctx) do
      if ctx[:trace] do
        Code.ensure_loaded!(Pages)
        Code.ensure_loaded!(Pages.Driver)
        Code.ensure_loaded!(Pages.Driver.Conn)
        Code.ensure_loaded!(Pages.Driver.LiveView)

        {:ok, tracer} = Tracer.start()

        session = :trace.session_create(:my_session, tracer, [])
        :trace.process(session, self(), true, [:call])
        :trace.function(session, {Pages, :click, :_}, true, [:local])
        :trace.function(session, {Pages, :new, :_}, true, [:local])
        :trace.function(session, {Pages, :submit_form, :_}, true, [:local])
        :trace.function(session, {Pages, :update_form, :_}, true, [:local])
        :trace.function(session, {Pages, :visit, :_}, true, [:local])
        :trace.function(session, {Pages.Driver.Conn, :click, :_}, true, [:local])
        :trace.function(session, {Pages.Driver.Conn, :new, :_}, true, [:local])
        :trace.function(session, {Pages.Driver.Conn, :submit_form, :_}, true, [:local])
        :trace.function(session, {Pages.Driver.Conn, :update_form, :_}, true, [:local])
        :trace.function(session, {Pages.Driver.Conn, :visit, :_}, true, [:local])

        ExUnit.Callbacks.on_exit(fn ->
          Tracer.pop_trace(tracer) |> dbg()
          Tracer.stop(tracer)
        end)
      end

      :ok
    end
  end
end
