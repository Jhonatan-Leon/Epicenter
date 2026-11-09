defmodule Epicenter.MixProject do
  use Mix.Project

  def project do
    [
      app: :epicenter,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [

      {:ecto, "~> 3.0"},
      {:plug, github: "elixir-plug/plug"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  def cli do
    [
      default_env: :local,
      preferred_env: [docs: :docs]
    ]
  end
end
