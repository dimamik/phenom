defmodule Phenom.MixProject do
  use Mix.Project

  @version "0.2.1"
  @source_url "https://github.com/dimamik/phenom"

  def project do
    [
      app: :phenom,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: false,
      aliases: aliases(),
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
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
        "Changelog" => "#{@source_url}/blob/main/installer/CHANGELOG.md"
      },
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE img)
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "img/logo.png",
      extras: ["README.md": [filename: "readme", title: "Phenom"]],
      source_ref: "v#{@version}",
      source_url_pattern: "#{@source_url}/blob/v#{@version}/installer/%{path}#L%{line}"
    ]
  end

  defp aliases do
    [
      publish: [
        "cmd git tag v#{@version}",
        "cmd git push",
        "cmd git push --tags",
        "hex.publish --yes"
      ]
    ]
  end
end
