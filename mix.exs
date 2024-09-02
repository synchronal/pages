defmodule Pages.MixProject do
  use Mix.Project

  @scm_url "https://github.com/synchronal/pages"
  @version "1.2.0"

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
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @scm_url,
      name: "Pages",
      package: package(),
      preferred_cli_env: [credo: :test, dialyzer: :test],
      source_url: @scm_url,
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  def cli do
    [
      preferred_envs: [credo: :test, dialyzer: :test]
    ]
  end

  # # #

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto, "> 0.0.0", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:gestalt, ">= 1.0.0 and < 3.0.0"},
      {:html_query, "~> 2.0.0"},
      {:jason, "~> 1.3", optional: true},
      {:markdown_formatter, "~> 1.0", only: :dev, runtime: false},
      {:mix_audit, "~> 2.0", only: :dev, runtime: false},
      {:mix_test_interactive, "~> 3.0", only: :dev, runtime: false},
      {:moar, "~> 1.10"},
      {:phoenix_ecto, "~> 4.4", only: :test, runtime: false},
      {:phoenix, "~> 1.6"},
      {:phoenix_live_view, "~> 0.16.4 or ~> 0.17"}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree,
      plt_core_path: "_build/plts/#{Mix.env()}",
      plt_local_path: "_build/plts/#{Mix.env()}"
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE.md"],
      groups_for_modules: [
        Drivers: [Pages.Driver, Pages.Driver.Conn, Pages.Driver.LiveView]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["synchronal.dev", "Erik Hanson", "Eric Saxby"],
      links: %{"GitHub" => @scm_url}
    ]
  end
end
