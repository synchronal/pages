import Config

config :pages, :drivers, [
  Pages.Driver.Conn,
  Pages.Driver.LiveView
]

import_config "#{config_env()}.exs"
