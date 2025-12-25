defmodule Mix.Tasks.Phenom.New.GeneratorTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Phenom.New.Generator

  @moduletag :tmp_dir

  describe "snake_to_pascal/1" do
    test "converts simple snake_case to PascalCase" do
      assert Generator.snake_to_pascal("my_app") == "MyApp"
    end

    test "handles single word" do
      assert Generator.snake_to_pascal("app") == "App"
    end

    test "handles multiple underscores" do
      assert Generator.snake_to_pascal("my_cool_app") == "MyCoolApp"
    end

    test "handles consecutive underscores" do
      assert Generator.snake_to_pascal("my__app") == "MyApp"
    end

    test "handles trailing underscore" do
      assert Generator.snake_to_pascal("my_app_") == "MyApp"
    end

    test "handles leading underscore" do
      assert Generator.snake_to_pascal("_my_app") == "MyApp"
    end
  end

  describe "validate_app_name!/1" do
    test "accepts valid snake_case names" do
      assert Generator.validate_app_name!("my_app") == :ok
      assert Generator.validate_app_name!("app") == :ok
      assert Generator.validate_app_name!("my_cool_app") == :ok
      assert Generator.validate_app_name!("app123") == :ok
      assert Generator.validate_app_name!("my_app_2") == :ok
    end

    test "rejects names starting with uppercase" do
      assert_raise Mix.Error, ~r/Invalid app name/, fn ->
        Generator.validate_app_name!("MyApp")
      end
    end

    test "rejects names starting with number" do
      assert_raise Mix.Error, ~r/Invalid app name/, fn ->
        Generator.validate_app_name!("123app")
      end
    end

    test "rejects names with hyphens" do
      assert_raise Mix.Error, ~r/Invalid app name/, fn ->
        Generator.validate_app_name!("my-app")
      end
    end

    test "rejects names with spaces" do
      assert_raise Mix.Error, ~r/Invalid app name/, fn ->
        Generator.validate_app_name!("my app")
      end
    end

    test "rejects empty string" do
      assert_raise Mix.Error, ~r/Invalid app name/, fn ->
        Generator.validate_app_name!("")
      end
    end
  end

  describe "validate_github_handle!/1" do
    test "accepts valid handles" do
      assert Generator.validate_github_handle!("dimamik") == :ok
      assert Generator.validate_github_handle!("user123") == :ok
      assert Generator.validate_github_handle!("my-org") == :ok
      assert Generator.validate_github_handle!("A") == :ok
      assert Generator.validate_github_handle!("a1") == :ok
    end

    test "rejects handles starting with hyphen" do
      assert_raise Mix.Error, ~r/Invalid GitHub handle/, fn ->
        Generator.validate_github_handle!("-invalid")
      end
    end

    test "rejects handles ending with hyphen" do
      assert_raise Mix.Error, ~r/Invalid GitHub handle/, fn ->
        Generator.validate_github_handle!("invalid-")
      end
    end

    test "rejects handles with underscores" do
      assert_raise Mix.Error, ~r/Invalid GitHub handle/, fn ->
        Generator.validate_github_handle!("my_org")
      end
    end

    test "rejects handles with spaces" do
      assert_raise Mix.Error, ~r/Invalid GitHub handle/, fn ->
        Generator.validate_github_handle!("my org")
      end
    end

    test "rejects empty string" do
      assert_raise Mix.Error, ~r/Invalid GitHub handle/, fn ->
        Generator.validate_github_handle!("")
      end
    end
  end

  describe "rename_files!/3" do
    test "renames files containing the old string", %{tmp_dir: tmp_dir} do
      # Create a file with old name
      File.write!(Path.join(tmp_dir, "phenom_config.ex"), "config")

      Generator.rename_files!(tmp_dir, "phenom", "my_app")

      refute File.exists?(Path.join(tmp_dir, "phenom_config.ex"))
      assert File.exists?(Path.join(tmp_dir, "my_app_config.ex"))
      assert File.read!(Path.join(tmp_dir, "my_app_config.ex")) == "config"
    end

    test "renames directories containing the old string", %{tmp_dir: tmp_dir} do
      # Create nested directory structure
      phenom_dir = Path.join(tmp_dir, "lib/phenom")
      File.mkdir_p!(phenom_dir)
      File.write!(Path.join(phenom_dir, "app.ex"), "defmodule Phenom.App")

      Generator.rename_files!(tmp_dir, "phenom", "my_app")

      refute File.exists?(Path.join(tmp_dir, "lib/phenom"))
      assert File.exists?(Path.join(tmp_dir, "lib/my_app"))
      assert File.exists?(Path.join(tmp_dir, "lib/my_app/app.ex"))
    end

    test "renames nested paths with multiple occurrences", %{tmp_dir: tmp_dir} do
      # Create lib/phenom_web/phenom_controller.ex
      nested_dir = Path.join(tmp_dir, "lib/phenom_web")
      File.mkdir_p!(nested_dir)
      File.write!(Path.join(nested_dir, "phenom_controller.ex"), "controller")

      Generator.rename_files!(tmp_dir, "phenom", "my_app")

      assert File.exists?(Path.join(tmp_dir, "lib/my_app_web/my_app_controller.ex"))
    end

    test "leaves files without old string unchanged", %{tmp_dir: tmp_dir} do
      File.write!(Path.join(tmp_dir, "config.exs"), "config")

      Generator.rename_files!(tmp_dir, "phenom", "my_app")

      assert File.exists?(Path.join(tmp_dir, "config.exs"))
      assert File.read!(Path.join(tmp_dir, "config.exs")) == "config"
    end
  end

  describe "replace_content!/2" do
    test "replaces content in text files", %{tmp_dir: tmp_dir} do
      File.write!(Path.join(tmp_dir, "app.ex"), """
      defmodule Phenom.Application do
        use Application
        # phenom config
      end
      """)

      Generator.replace_content!(tmp_dir, %{
        "Phenom" => "MyApp",
        "phenom" => "my_app"
      })

      content = File.read!(Path.join(tmp_dir, "app.ex"))
      assert content =~ "defmodule MyApp.Application"
      assert content =~ "# my_app config"
      refute content =~ "Phenom"
      refute content =~ "phenom"
    end

    test "handles multiple replacements", %{tmp_dir: tmp_dir} do
      File.write!(Path.join(tmp_dir, "config.exs"), """
      config :phenom, PhenomWeb.Endpoint,
        github: "dimamik"
      """)

      Generator.replace_content!(tmp_dir, %{
        "Phenom" => "MyApp",
        "phenom" => "my_app",
        "dimamik" => "myuser"
      })

      content = File.read!(Path.join(tmp_dir, "config.exs"))
      assert content =~ "config :my_app, MyAppWeb.Endpoint"
      assert content =~ ~s(github: "myuser")
    end

    test "skips binary files", %{tmp_dir: tmp_dir} do
      binary_content = <<0, 1, 2, 3, 80, 104, 101, 110, 111, 109>>
      File.write!(Path.join(tmp_dir, "image.png"), binary_content)

      Generator.replace_content!(tmp_dir, %{"Phenom" => "MyApp"})

      # Binary file should be unchanged
      assert File.read!(Path.join(tmp_dir, "image.png")) == binary_content
    end

    test "processes nested directories", %{tmp_dir: tmp_dir} do
      nested_dir = Path.join(tmp_dir, "lib/phenom")
      File.mkdir_p!(nested_dir)
      File.write!(Path.join(nested_dir, "worker.ex"), "defmodule Phenom.Worker")

      Generator.replace_content!(tmp_dir, %{"Phenom" => "MyApp"})

      content = File.read!(Path.join(nested_dir, "worker.ex"))
      assert content == "defmodule MyApp.Worker"
    end
  end
end
