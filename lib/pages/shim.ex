defmodule Pages.Shim do
  @moduledoc false

  ## Pages.Shim is used to unwrap macros provided by Phoenix which require
  ## @endpoint to be set in the calling file. It is inherently unsafe, and should
  ## be tested against every version of Phoenix and PhoenixLiveView to ensure that
  ## private changes to those libraries do not break compatibility.

  use Gestalt

  def __dispatch(conn, method, path, params \\ %{}),
    do: Phoenix.ConnTest.dispatch(conn, __endpoint(), method, path, params)

  def __endpoint do
    gestalt_config(:pages, :phoenix_endpoint, self()) ||
      raise("""
      Unable to find configured endpoint.

          config :pages, :phoenix_endpoint, My.EndpointModule
      """)
  end

  def __follow_trigger_action(form, conn) do
    {method, path, form_data} = Phoenix.LiveViewTest.__render_trigger_event__(form)
    __dispatch(conn, method, path, form_data)
  end
end
