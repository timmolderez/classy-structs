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

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:ex_doc, "~> 0.16", only: :dev, runtime: false}]
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
