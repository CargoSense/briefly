defmodule Briefly.Mixfile do
  use Mix.Project

  def project do
    [app: :briefly,
     version: "0.3.0",
     elixir: "~> 1.3",
     source_url: "https://github.com/CargoSense/briefly",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger],
     mod: {Briefly, []},
     env: default_env()]
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
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.8", only: :dev}]
  end

  defp package do
    [description: "Simple, robust temporary file support",
     files: ["lib", "config", "mix.exs", "README*", "LICENSE"],
     contributors: ["Bruce Williams"],
     licenses: ["Apache 2"],
     links: %{github: "https://github.com/CargoSense/briefly"}]
  end

  defp default_env do
    [directory: [{:system, "TMPDIR"}, {:system, "TMP"}, {:system, "TEMP"}, "/tmp"],
     default_prefix: "briefly",
     default_extname: ""]
  end

end
