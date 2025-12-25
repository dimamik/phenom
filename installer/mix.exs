defmodule Phenom.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dimamik/phenom"

  def project do
    [
      app: :phenom,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: false,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def cli do
    [preferred_envs: [docs: :docs]]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  defp description do
    "Phoenix starter you'd build yourself, if you had the time."
  end

  defp package do
    [
      name: "phenom",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w(lib .formatter.exs mix.exs ../README.md ../LICENSE ../img)
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "../img/logo.png",
      extras: ["../README.md": [filename: "readme", title: "Phenom"]],
      source_ref: "v#{@version}"
    ]
  end
end
