defmodule LoggerEtsBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :logger_ets_backend,
      version: "0.0.1",
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    "A simple `Logger` backend which writes logs to an ETS table."
  end

  defp package() do
    [
      name: "logger_ets_backend",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/OldhamMade/logger_ets_backend"}
    ]
  end
end
