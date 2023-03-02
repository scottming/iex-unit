defmodule IExUnit.MixProject do
  use Mix.Project

  def project do
    [
      app: :iex_unit,
      version: "0.1.0",
      elixir: "~> 1.14",
      description: description(),
      package: package(),
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
      {:ex_doc, "~> 0.29", only: :dev}
    ]
  end

  defp description do
    """
    A utility module that helps you run unit tests faster
    """
  end

  defp package do
    [
      name: "iex_unit",
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Scott Ming (therealscottming@gmail.com)"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/scottming/iex_unit"
      }
    ]
  end
end
