defmodule Briefly.Mixfile do
  use Mix.Project

  @version "0.4.0"

  @source_url "https://github.com/CargoSense/briefly"

  def project do
    [
      app: :briefly,
      version: "0.4.0",
      elixir: "~> 1.11",
      source_url: @source_url,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      preferred_cli_env: [
        {:docs, :docs},
        {:"hex.publish", :docs}
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :crypto], mod: {Briefly, []}, env: default_env()]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.29", only: :docs, runtime: false}
    ]
  end

  defp package do
    [
      description: "Simple, robust temporary file support",
      files: ["lib", "config", "mix.exs", "README*", "LICENSE"],
      contributors: ["Bruce Williams", "Michael A. Crumm Jr."],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_url: @source_url,
      source_ref: "v#{@version}",
      deps: [],
      language: "en",
      formatters: ["html"],
      main: "usage",
      extras: ["guides/usage.livemd"]
    ]
  end

  defp default_env do
    [
      directory: [{:system, "TMPDIR"}, {:system, "TMP"}, {:system, "TEMP"}, "/tmp"],
      sub_directory_prefix: "briefly",
      default_prefix: "briefly",
      default_extname: ""
    ]
  end
end
