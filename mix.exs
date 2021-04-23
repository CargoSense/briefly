defmodule Briefly.Mixfile do
  use Mix.Project

  @source_url "https://github.com/CargoSense/briefly"
  @version "0.4.0"

  def project do
    [
      app: :briefly,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      applications: [:logger],
      mod: {Briefly, []},
      env: default_env()
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: "Simple, robust temporary file support",
      files: ["lib", "config", "mix.exs", "README*", "LICENSE"],
      contributors: ["Bruce Williams"],
      licenses: ["Apache-2"],
      links: %{GitHub: @source_url}
    ]
  end

  defp default_env do
    [
      directory: [
        {:system, "TMPDIR"},
        {:system, "TMP"},
        {:system, "TEMP"},
        "/tmp"
      ],
      default_prefix: "briefly",
      default_extname: ""
    ]
  end

  defp docs do
    [
      main: "Briefly",
      source_url: @source_url,
      source_ref: "v#{@version}",
      api_reference: false,
      extra_section: [],
      formatters: ["html"]
    ]
  end
end
