defmodule Gatling.Tasks.DeployUpgradeTest do
  use ExUnit.Case

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

    IO.puts("")

    :ok
  end

  test "Deploy, then upgrade" do
    Mix.Tasks.Gatling.Deploy.run(["sample_project"])

    assert File.exists?(Path.join(
      [Gatling.Utilities.deploy_dir("sample_project"), "sample_project.tar.gz"]
    ))

    assert File.exists?(Path.join(
      [Gatling.Utilities.nginx_dir , "sites-available", "sample_project"]
    ))

    assert File.exists?(Path.join(
      [Gatling.Utilities.nginx_dir , "sites-enabled", "sample_project"]
    ))

    assert File.exists?(Path.join(
      [Gatling.Utilities.etc_dir , "sample_project"]
    ))

    Mix.Tasks.Gatling.Upgrade.run(["sample_project"])

    #test/sample_project/mix.exs
    path = Path.join(
      [Gatling.Utilities.deploy_dir("sample_project"), "releases", "0.0.0", "sample_project.tar.gz"]
    )
    assert File.exists?(path), path
  end

end
