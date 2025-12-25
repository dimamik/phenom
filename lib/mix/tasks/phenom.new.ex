defmodule Mix.Tasks.Phenom.New do
  @moduledoc """
  Creates a new project from the latest `dimamik/phenom` template.

  This task clones the template repo and performs the plain-text renaming
  steps to customize it for your new app.

  ## Usage

      mix phenom.new APP_NAME [--github HANDLE] [--branch BRANCH]

  ### Options

    * `--github` - GitHub username/org to replace `dimamik` (used in deployment docs)
    * `--branch` - Branch/tag to clone (default: `main`)

  The destination directory is `./APP_NAME`.
  """

  use Mix.Task

  @shortdoc "Creates a new project from the Phenom template"

  @switches [github: :string, branch: :string]

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, args, invalid} = OptionParser.parse(argv, strict: @switches)

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    case args do
      [app_name] ->
        Mix.Tasks.Phenom.New.Generator.run(%{
          app_name: app_name,
          github: opts[:github],
          branch: opts[:branch] || "main"
        })

      _ ->
        Mix.shell().error("Usage: mix phenom.new APP_NAME [--github HANDLE] [--branch BRANCH]")
        Mix.raise("Invalid arguments")
    end
  end
end
