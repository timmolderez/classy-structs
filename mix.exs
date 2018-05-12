defmodule Class.MixProject do
  use Mix.Project

  def project do
    [
      app: :classy_structs,
      version: "0.9.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/timmolderez/classy-structs"
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp description() do
    "Classy structs provides object-oriented features, such as inheritance and polymorphism, on top of Elixir's structs."
  end

  defp package() do
    [
      maintainers: ["Tim Molderez"],
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => "https://github.com/timmolderez/classy-structs"}
    ]
  end
end
