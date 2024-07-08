defmodule Test.Site.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :pages

  socket("/live", Phoenix.LiveView.Socket)

  defoverridable config: 1,
                 config: 2,
                 script_name: 0,
                 static_path: 1,
                 url: 0

  def call(conn, _) do
    %{conn | secret_key_base: config(:secret_key_base)}
    |> Plug.Conn.put_private(:phoenix_endpoint, __MODULE__)
    |> Test.Site.Router.call([])
  end

  # def url, do: [host: Test.Site.host(), port: Test.Site.port()]
  def url, do: "http://#{Test.Site.host()}:#{Test.Site.port()}"
  def script_name, do: []
  def static_path(path), do: "/static" <> path
  def config(:live_view), do: [signing_salt: String.duplicate("0", 20)]
  def config(:secret_key_base), do: String.duplicate("abcdefgh", 8)
  def config(:cache_static_manifest_latest), do: Process.get(:cache_static_manifest_latest)
  def config(:otp_app), do: :pages
  def config(:port), do: Test.Site.port()
  def config(:pubsub_server), do: Phoenix.LiveView.PubSub
  def config(:render_errors), do: [view: __MODULE__]
  def config(:static_url), do: [path: "/static"]
  def config(which), do: super(which)
  def config(which, default), do: super(which, default)
end
