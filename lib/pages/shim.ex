defmodule Pages.Shim do
  # credo:disable-for-this-file

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
      raise(Pages.Error, """
      Unable to find configured endpoint.

          config :pages, :phoenix_endpoint, My.EndpointModule
      """)
  end

  def __follow_trigger_action(form, conn) do
    test_module = Phoenix.LiveViewTest
    old_function = :__render_trigger_event__
    new_function = :__render_trigger_submit__

    cond do
      function_exported?(test_module, old_function, 1) ->
        {method, path, form_data} = apply(test_module, old_function, [form])

        __dispatch(conn, method, path, form_data)
        |> __retain_connect_params(conn)

      function_exported?(test_module, new_function, 4) ->
        {method, path, form_data} =
          apply(test_module, new_function, [
            form,
            :follow_trigger_action,
            "phx-trigger-action",
            "could not follow trigger action because form #{inspect(form.selector)} " <>
              "does not have a phx-trigger-action attribute"
          ])

        __dispatch(conn, method, path, form_data)
        |> __retain_connect_params(conn)

      true ->
        raise Pages.Error, "This version of #{test_module} does not define #{old_function} or #{new_function}"
    end
  end

  def __retain_connect_params(conn, original_conn) do
    if Map.has_key?(original_conn.private, :live_view_connect_params),
      do: Phoenix.LiveViewTest.put_connect_params(conn, original_conn.private.live_view_connect_params),
      else: conn
  end
end
