defmodule Fw.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "rpi3"

  def project do
    [app: :fw,
     version: "0.1.0",
     target: @target,
     archives: [nerves_bootstrap: "~> 0.2.1"],
     
     deps_path: "../../deps/#{@target}",
     build_path: "../../_build/#{@target}",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(Mix.env),
     deps: deps() ++ system(@target, Mix.env)]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Fw, []},
     applications: applications(Mix.env)]
  end

  def applications(:prod), do: [:nerves_interim_wifi, :logger_multicast_backend, :nerves_firmware_http, :nerves_ntp | general_apps]
  def applications(_), do: general_apps

  defp general_apps, do: [:runtime_tools, :logger, :sensors, :pump, :mqtt, :web]

  def deps do
    [
      {:nerves, "~> 0.4.0"},
      {:nerves_interim_wifi, "~> 0.1.0", only: :prod},
      {:nerves_ntp, github: "evokly/nerves_ntp", only: :prod},
      {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http", only: :prod},
      {:logger_multicast_backend, github: "cellulose/logger_multicast_backend"},
      {:sensors, in_umbrella: true},
      {:pump, in_umbrella: true},
      {:mqtt, in_umbrella: true},
      {:web, in_umbrella: true}
    ]
  end

  def system(target, :prod) do
    [{:"nerves_system_#{target}", ">= 0.0.0"}]
  end
  def system(_, _), do: []

  def aliases(:prod) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end
  def aliases(_), do: []

end
