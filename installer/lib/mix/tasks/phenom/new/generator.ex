defmodule Mix.Tasks.Phenom.New.Generator do
  @moduledoc false

  @banner_lines [
    "",
    "╔═══════════════════════════════════════════════════════════╗",
    "║                                                           ║",
    "║                      ⚡ PHENOM ⚡                         ║",
    "║                                                           ║",
    "║   An opinionated template for your new Phoenix project    ║",
    "║                                                           ║",
    "╚═══════════════════════════════════════════════════════════╝",
    ""
  ]

  @template_repo "https://github.com/dimamik/phenom.git"

  @old_app_name "phenom"
  @old_app_module "Phenom"
  @old_github_handle "dimamik"

  @typep options :: %{
           required(:app_name) => String.t(),
           optional(:github) => String.t() | nil,
           required(:branch) => String.t(),
           optional(:template_repo) => String.t()
         }

  @spec run(options()) :: :ok
  def run(%{app_name: app_name} = opts) do
    print_banner()

    validate_app_name!(app_name)

    dest = Path.expand(app_name)

    if File.exists?(dest) do
      Mix.raise("Destination already exists: #{dest}")
    end

    github = opts[:github] || prompt_github_handle!()
    validate_github_handle!(github)

    shell = Mix.shell()

    template_repo = Map.get(opts, :template_repo, @template_repo)

    shell.info("Cloning #{template_repo} into #{dest}...")
    git_clone!(template_repo, dest, opts.branch)

    # Remove template git history and installer directory since these are
    # configuration artefacts
    File.rm_rf!(Path.join(dest, ".git"))
    File.rm_rf!(Path.join(dest, "installer"))

    shell.info("Customizing project...")

    new_app_module = snake_to_pascal(app_name)

    rename_files!(dest, @old_app_name, app_name)

    replace_content!(dest, %{
      @old_app_module => new_app_module,
      @old_app_name => app_name,
      @old_github_handle => github
    })

    ensure_dotenv!(dest)

    shell.info("Done. Next steps (inside #{app_name}):")
    shell.info("  mix setup")
    shell.info("  mix phx.server")

    :ok
  end

  defp print_banner do
    shell = Mix.shell()
    Enum.each(@banner_lines, fn line -> shell.info(line) end)
  end

  @doc false
  def validate_app_name!(name) do
    if Regex.match?(~r/^[a-z][a-z0-9_]*$/, name) do
      :ok
    else
      Mix.raise("Invalid app name: #{inspect(name)} (use lowercase snake_case, e.g. my_app)")
    end
  end

  @doc false
  def validate_github_handle!(handle) do
    if Regex.match?(~r/^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$/, handle) do
      :ok
    else
      Mix.raise("Invalid GitHub handle: #{inspect(handle)}")
    end
  end

  defp prompt_github_handle! do
    case Mix.shell().prompt("GitHub username/org (for storing GHCR images):") do
      handle when is_binary(handle) ->
        handle
        |> String.trim()
        |> case do
          "" -> Mix.raise("GitHub handle cannot be empty (or pass --github)")
          v -> v
        end
    end
  end

  @doc false
  def snake_to_pascal(value) do
    value
    |> String.split("_", trim: true)
    |> Enum.map_join(fn part ->
      case part do
        "" -> ""
        _ -> String.capitalize(part)
      end
    end)
  end

  defp git_clone!(repo, dest, branch) do
    args = ["clone", "--depth", "1", "--branch", branch, repo, dest]
    {output, status} = System.cmd("git", args, stderr_to_stdout: true)

    if status != 0 do
      Mix.raise("git clone failed (status #{status}):\n#{output}")
    end
  end

  @doc false
  def rename_files!(root, old_string, new_string) do
    for path <- list_paths_depth_first(root),
        rel_path = Path.relative_to(path, root),
        String.contains?(rel_path, old_string) do
      new_rel_path = String.replace(rel_path, old_string, new_string)
      new_path = Path.join(root, new_rel_path)

      # When traversing depth-first, children may already have been renamed into
      # the destination tree. Avoid crashing on such collisions.
      if path != new_path and not File.exists?(new_path) do
        File.mkdir_p!(Path.dirname(new_path))
        File.rename!(path, new_path)
        cleanup_empty_parents(Path.dirname(path), root)
      end
    end
  end

  # Recursively remove empty parent directories up to (but not including) root
  defp cleanup_empty_parents(dir, root) do
    cond do
      dir == root ->
        :ok

      not File.dir?(dir) ->
        :ok

      File.ls!(dir) == [] ->
        File.rmdir!(dir)
        cleanup_empty_parents(Path.dirname(dir), root)

      true ->
        :ok
    end
  end

  @doc false
  def replace_content!(root, replacements) when is_map(replacements) do
    for path <- list_files(root), text_file?(path) do
      content = File.read!(path)

      new_content =
        Enum.reduce(replacements, content, fn {from, to}, acc -> String.replace(acc, from, to) end)

      File.write!(path, new_content)
    end
  end

  defp ensure_dotenv!(root) do
    env_path = Path.join(root, ".env")
    sample_path = Path.join(root, ".env.sample")

    cond do
      File.exists?(env_path) ->
        Mix.shell().info("Warning: .env already exists, leaving it unchanged")
        :ok

      File.exists?(sample_path) ->
        File.cp!(sample_path, env_path)

      true ->
        :ok
    end
  end

  defp list_paths_depth_first(root) do
    root
    |> File.ls!()
    |> Enum.map(&Path.join(root, &1))
    |> Enum.flat_map(fn path ->
      if File.dir?(path) and not excluded_dir?(path) do
        list_paths_depth_first(path) ++ [path]
      else
        [path]
      end
    end)
  end

  defp list_files(root) do
    root
    |> File.ls!()
    |> Enum.map(&Path.join(root, &1))
    |> Enum.flat_map(fn path ->
      cond do
        File.dir?(path) and not excluded_dir?(path) -> list_files(path)
        File.regular?(path) -> [path]
        true -> []
      end
    end)
  end

  defp excluded_dir?(path) do
    base = Path.basename(path)
    base in [".git", "deps", "_build", "node_modules"] or String.starts_with?(base, ".")
  end

  defp text_file?(path) do
    ext = Path.extname(path)

    ext in [
      ".ex",
      ".exs",
      ".heex",
      ".eex",
      ".leex",
      ".md",
      ".txt",
      ".json",
      ".js",
      ".ts",
      ".css",
      ".env",
      ".sample",
      ".toml",
      ".yml",
      ".yaml",
      ".sh",
      ".dockerfile",
      ".lock",
      ""
    ] and not binary_ext?(ext)
  end

  defp binary_ext?(ext) do
    ext in [
      ".beam",
      ".so",
      ".png",
      ".jpg",
      ".jpeg",
      ".gif",
      ".ico",
      ".woff",
      ".woff2",
      ".ttf",
      ".eot"
    ]
  end
end
