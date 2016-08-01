defmodule Gatling.Tasks.DeployTest do
  use ExUnit.Case

  setup do
    cleanup

    build_path = Gatling.Utilities.build_path("sample_project")
    File.mkdir_p(build_path)
    File.cp_r("test/sample_project", build_path)
    File.mkdir_p(Gatling.Utilities.nginx_path <> "/sites-available")
    File.mkdir_p(Gatling.Utilities.nginx_path <> "/sites-enabled")
    File.mkdir_p(Gatling.Utilities.etc_path)

    :ok
  end

  test ".run" do
    Mix.Tasks.Gatling.Deploy.run(["sample_project"])

    assert File.exists?(Path.join(
      [Gatling.Utilities.deploy_dir("sample_project"), "sample_project.tar.gz"]
    ))

    assert File.exists?(Path.join(
      [Gatling.Utilities.nginx_path , "sites-available", "sample_project"]
    ))

    assert File.exists?(Path.join(
      [Gatling.Utilities.nginx_path , "sites-enabled", "sample_project"]
    ))

    assert File.exists?(Path.join(
      [Gatling.Utilities.etc_path , "sample_project"]
    ))

    cleanup
  end

  def cleanup do
    File.rm_rf("test/root")
    File.rm_rf("test/sample_project/rel")
  end

end
