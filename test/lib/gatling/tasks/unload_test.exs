defmodule Gatling.Tasks.UnloadTest do
  use ExUnit.Case

  import Gatling.TestHelpers

  setup do
    project = "sample_project"
    build_dir = Gatling.Utilities.build_dir(project)
    File.mkdir_p(build_dir)
    File.cp_r("test/sample_project", build_dir)

    File.mkdir_p(Gatling.Utilities.deploy_dir(project))

    File.mkdir_p(Gatling.Utilities.nginx_dir <> "/sites-available")
    File.mkdir_p(Gatling.Utilities.nginx_dir <> "/sites-enabled")
    File.mkdir_p(Gatling.Utilities.etc_dir)

    File.write(Gatling.Utilities.etc_path(project), "service")
    File.write(Gatling.Utilities.nginx_available_path(project), "available")
    File.ln_s(Gatling.Utilities.nginx_available_path(project), Gatling.Utilities.nginx_enabled_path(project))

    on_exit fn ->
      File.rm_rf("test/root")
      File.rm_rf("test/sample_project/rel")
    end

    :ok
  end

  test ".run" do
    project = "sample_project"
    build_dir = Gatling.Utilities.build_dir(project)
    deploy_dir = Gatling.Utilities.deploy_dir(project)
    etc_path = Gatling.Utilities.etc_path(project)
    enabled_path = Gatling.Utilities.nginx_enabled_path(project)
    available_path = Gatling.Utilities.nginx_available_path(project)

    assert_exists build_dir
    assert_exists deploy_dir
    assert_exists etc_path
    assert_exists enabled_path
    assert_exists available_path

    Mix.Tasks.Gatling.Unload.run([project])

    refute_exists build_dir
    refute_exists deploy_dir
    refute_exists etc_path
    refute_exists enabled_path
    refute_exists available_path
  end

end
