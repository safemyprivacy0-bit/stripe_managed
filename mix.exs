defmodule StripeManaged.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/alexanderp/stripe_managed"

  def project do
    [
      app: :stripe_managed,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "StripeManaged",
      description: "Elixir client for Stripe Managed Payments (merchant of record)",
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.16", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:mox, "~> 1.1", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
