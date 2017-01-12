defmodule Gatling.Tasks.DeployUpgradeTest do
  use ExUnit.Case

  import Gatling.TestHelpers

  setup do
    build_dir = Gatling.Utilities.build_dir("sample_project")
    File.mkdir_p(build_dir)
    File.cp_r("test/sample_project", build_dir)

    File.mkdir_p(Gatling.Utilities.nginx_dir <> "/sites-available")
    File.mkdir_p(Gatling.Utilities.nginx_dir <> "/sites-enabled")
    File.mkdir_p(Gatling.Utilities.etc_dir)

    on_exit fn ->
      File.rm_rf("test/root")
      File.rm_rf("test/sample_project/rel")
    end

    :ok
  end

  test "Deploy, then upgrade" do
    Mix.Tasks.Gatling.Deploy.run(["sample_project"])

    assert_exists Path.join([Gatling.Utilities.build_dir("sample_project"), "rel/config.exs"])
    assert_exists Gatling.Utilities.deploy_path("sample_project")
    assert_exists Path.join([Gatling.Utilities.nginx_dir , "sites-available", "sample_project"])
    assert_exists Path.join([Gatling.Utilities.nginx_dir , "sites-enabled", "sample_project"])
    assert_exists Path.join([Gatling.Utilities.etc_dir , "sample_project"])

    Mix.Tasks.Gatling.Upgrade.run(["sample_project"])

    assert_exists Path.join([Gatling.Utilities.deploy_dir("sample_project"), "releases", "0.0.1470406670", "sample_project.tar.gz"])
  end

end
