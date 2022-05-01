defmodule Pages.MixProject do
  use Mix.Project

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def project do
    [
      app: :pages,
      deps: deps(),
      description: "Page pattern for interacting with web pages",
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Pages",
      preferred_cli_env: [credo: :test, dialyzer: :test],
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  # # #

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:euclid, "~> 0.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:floki, "~> 0.32.1"},
      {:gestalt, "~> 1.0"},
      {:jason, "~> 1.3", optional: true},
      {:mix_audit, "~> 1.0", only: :dev, runtime: false},
      {:phoenix, "~> 1.6"},
      {:phoenix_live_view, "~> 0.17.9"}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      main: "Pages",
      extras: ["README.md", "LICENSE.md"],
      groups_for_modules: [
        Drivers: [Pages.Driver, Pages.Driver.Conn, Pages.Driver.LiveView]
      ]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]
end
