defmodule Gatling.UtilitiesTest do
  use ExUnit.Case, async: true

  alias Gatling.Utilities

  defp release_dir(version) do
    Path.join([
      Utilities.build_dir("sample_project"),
      "rel", "sample_project", "releases",
      version
    ])
  end

  defp mk_release_dir(version) do
    File.mkdir_p release_dir(version)
  end

  defp rm_release_dir(version) do
    File.rm_rf release_dir(version)
  end

  setup do
    build_dir = Utilities.build_dir("sample_project")
    File.mkdir_p(build_dir)
    File.cp_r("test/sample_project", build_dir)

    on_exit fn ->
      File.rm_rf("test/root")
      File.rm_rf("test/sample_project/rel")
    end

    :ok
  end

  # configured in config/test.exs
  test ".build_dir" do
    expected_path = "/gatling/test/root/home/ubuntu/foo"
    regex = ~r/#{expected_path}$/
    path = Utilities.build_dir("foo")
    assert Regex.match?(regex, path)
  end

  describe ".releases" do
    test "loads releases" do
      assert Utilities.releases("sample_project") == []

      version = "0.0.1"
      mk_release_dir(version)
      assert Utilities.releases("sample_project") == [version]

      on_exit fn ->
        rm_release_dir(version)
      end
    end

    test "orders releases correctly" do
      releases = ["0.0.1", "0.0.2", "0.0.9", "0.0.10", "0.0.11", "0.1.0", "0.1.1", "0.1.11", "0.2.0"]
      for version <- releases, do: mk_release_dir(version)

      assert Utilities.releases("sample_project") == releases

      on_exit fn ->
        for version <- releases, do: rm_release_dir(version)
      end
    end
  end

  test ".release_config_path" do
    expected_path = "/gatling/test/root/home/ubuntu/foo/rel/config.exs"
    regex = ~r/#{expected_path}$/
    path = Utilities.release_config_path("foo")
    assert Regex.match?(regex, path)
  end

  test ".deploy_dir" do
    expected_path = "/gatling/test/root/home/ubuntu/deployments/sample_project"
    regex = ~r/#{expected_path}$/
    path = Utilities.deploy_dir("sample_project")
    assert Regex.match?(regex, path)
  end

  test ".deploy_path" do
    expected_path = "/gatling/test/root/home/ubuntu/deployments/sample_project/sample_project.tar.gz"
    regex = ~r/#{expected_path}$/
    path = Utilities.deploy_path("sample_project")
    assert Regex.match?(regex, path)
  end

  test ".config_path" do
    expected_path = "/gatling/test/root/home/ubuntu/deployments/sample_project/.env"
    regex = ~r/#{expected_path}$/
    path = Utilities.config_path("sample_project")
    assert Regex.match?(regex, path)
  end

  test ".upgrade_dir" do
    expected_path = "/gatling/test/root/home/ubuntu/deployments/sample_project/releases/0.0.1470406670"
    regex = ~r/#{expected_path}$/
    path = Utilities.upgrade_dir("sample_project")
    assert Regex.match?(regex, path)
  end

  test ".upgrade_path" do
    expected_path = "/gatling/test/root/home/ubuntu/deployments/sample_project/releases/0.0.1470406670/sample_project.tar.gz"
    regex = ~r/#{expected_path}$/
    path = Utilities.upgrade_path("sample_project")
    assert Regex.match?(regex, path)
  end

  test ".nginx_dir" do
    expected_path = "/gatling/test/root/etc/nginx"
    regex = ~r/#{expected_path}$/
    path = Utilities.nginx_dir
    assert Regex.match?(regex, path)
  end

  test ".nginx_config" do
    regex = ~r/server/
    config_file = Utilities.nginx_config("sample_project")
    assert Regex.match?(regex, config_file), """
    #{inspect regex} didn't match anything in:
    #{config_file}
    """
  end

  test ".etc_dir" do
    expected_path = "/gatling/test/root/etc/init.d"
    regex = ~r/#{expected_path}$/
    path = Utilities.etc_dir
    assert Regex.match?(regex, path)
  end

  test ".etc_path" do
    expected_path = "/gatling/test/root/etc/init.d/sample_project"
    regex = ~r/#{expected_path}$/
    path = Utilities.etc_path("sample_project")
    assert Regex.match?(regex, path)
  end

   test ".built_release_path" do
    expected_path = "/gatling/test/root/home/ubuntu/sample_project/_build/prod/rel/sample_project/releases/0.0.1470406670/sample_project.tar.gz"
    regex = ~r/#{expected_path}$/
    path = Utilities.built_release_path("sample_project")
    assert Regex.match?(regex, path)
   end

   test ".git_hook_path" do
    expected_path = "/gatling/test/root/home/ubuntu/sample_project/.git/hooks/post-update"
    regex = ~r/#{expected_path}$/
    path = Utilities.git_hook_path("sample_project")
    assert Regex.match?(regex, path), path
   end

  test ".version" do
    assert Utilities.version("sample_project") == "0.0.1470406670"
  end

  test ".mix_tasks" do
    tasks = assert Utilities.mix_tasks("sample_project")
    assert Enum.count(tasks) > 1
  end

  test ".upgrade_callback_module" do
    module = Utilities.callback_module("sample_project", task: "upgrade")
    assert module
    assert module.before_mix_deps_get(nil) == "before_mix_deps_get"

    module = Utilities.callback_module("sample_project", task: "deploy")
    assert module
    assert module.before_mix_deps_get(nil) == "before_mix_deps_get"
  end

end
