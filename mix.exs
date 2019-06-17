defmodule LoggerEtsBackend.MixProject do
  use Mix.Project

  @version "0.0.2"
  @github "https://github.com/OldhamMade/logger_ets_backend"

  def project do
    [
      app: :logger_ets_backend,
      version: @version,
      elixir: "~> 1.3",
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
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
    "A simple `Logger` backend which writes log entries to an ETS table."
  end

  defp package() do
    [
      name: "logger_ets_backend",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp docs do
    [extras: ["README.md"],
     main: "readme",
     source_ref: "v#{@version}",
     source_url: @github]
  end
end
