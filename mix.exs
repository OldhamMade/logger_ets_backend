defmodule LoggerEtsBackend.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github "https://github.com/OldhamMade/logger_ets_backend"

  def project do
    [
      app: :logger_ets_backend,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Docs
      name: "logger_ets_backend",
      docs: docs(),

      # Coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:excoveralls, ">= 0.0.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    "A simple `Logger` backend which writes log entries to an ETS table."
  end

  defp package() do
    [
      maintainers: ["Phillip Oldham"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @github},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [extras: ["README.md"], main: "readme", source_ref: "v#{@version}", source_url: @github]
  end
end
