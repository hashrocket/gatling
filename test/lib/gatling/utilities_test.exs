defmodule Gatling.UtilitiesTest do
  use ExUnit.Case, async: true

  alias Gatling.Utilities

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
    expected_path = "/gatling/test/root/home/ubuntu/sample_project/rel/sample_project/releases/0.0.1470406670/sample_project.tar.gz"
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
    assert Utilities.mix_tasks("sample_project") ==  ["run", "app.start", "app.tree", "archive", "archive.build", "archive.install", "archive.uninstall", "clean", "cmd", "compile", "deps", "deps.clean", "deps.compile", "deps.get", "deps.tree", "deps.unlock", "deps.update", "do", "escript", "escript.build", "escript.install", "escript.uninstall", "help", "hex", "hex.build", "hex.config", "hex.docs", "hex.info", "hex.key", "hex.outdated", "hex.owner", "hex.public_keys", "hex.publish", "hex.registry", "hex.search", "hex.user", "loadconfig", "local", "local.hex", "local.phoenix", "local.public_keys", "local.rebar", "new", "phoenix.new", "profile.fprof", "run", "test", "xref"]
  end


end
