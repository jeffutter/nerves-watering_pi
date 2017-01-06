defmodule Sensors.Mixfile do
  use Mix.Project

  def project do
    [app: :sensors,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: applications(Mix.env),
     mod: {Sensors, []}]
  end

  def applications(:prod), do: [:elixir_ale | general_apps()]
  def applications(_), do: general_apps()

  defp general_apps, do: [:logger, :gproc, :prometheus_ex, :poison, :timex]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:elixir_ale, "~> 0.5.6", only: :prod},
      {:prometheus_ex, "~> 1.1.0"},
      {:poison, "~> 3.0.0", override: true},
      {:gproc, "~> 0.6.1"},
      {:timex, "~> 3.0"}
    ]
  end
end
