defmodule Test.Site.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :setup_session do
    plug(Plug.Session,
      store: :cookie,
      key: "_pages_test_key",
      signing_salt: "00000000000"
    )

    plug(:fetch_session)
  end

  pipeline :browser do
    plug(:setup_session)
    plug(:accepts, ["html"])
    plug(:fetch_live_flash)
  end

  scope "/" do
    pipe_through(:browser)

    live("/live", Test.Site.PageLive)
    live("/live/form", Test.Site.FormLive)
    live("/live/final", Test.Site.PageLive, :final)
    live("/live/navigate", Test.Site.NavigateLive)
    live("/live/redirect", Test.Site.RedirectLive)
    live("/live/rerender", Test.Site.RerenderLive)
    get("/pages/show", Test.Site.PageController, :show)
  end
end
