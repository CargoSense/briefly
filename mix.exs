defmodule Briefly.Mixfile do
  use Mix.Project

  @source_url "https://github.com/CargoSense/briefly"
  @version "0.5.0"

  def project do
    [
      app: :briefly,
      version: @version,
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

  def application do
    [extra_applications: [:logger, :crypto], mod: {Briefly, []}, env: default_env()]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.29", only: :docs, runtime: false}
    ]
  end

  defp package do
    [
      description: "Simple, robust temporary file support",
      files: ["lib", "config", "mix.exs", "README*", "LICENSE", "CHANGELOG.md"],
      contributors: ["Bruce Williams", "Michael A. Crumm Jr."],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_url: @source_url,
      source_ref: "v#{@version}",
      language: "en",
      formatters: ["html"],
      main: "usage",
      extras: ["guides/usage.livemd", "CHANGELOG.md"]
    ]
  end

  defp default_env do
    [
      directory: [{:system, "TMPDIR"}, {:system, "TMP"}, {:system, "TEMP"}, "/tmp"],
      directory_mode: 0o755,
      default_prefix: "briefly",
      default_extname: ""
    ]
  end
end
