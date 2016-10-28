defmodule Gatling.Tasks.ConfigTest do
  use ExUnit.Case, async: true

  test "Setting config" do
    on_exit fn-> File.rm_rf("test/root") end

    env_path = Gatling.Utilities.deploy_dir("sample_project")
    config_path = Gatling.Utilities.config_path("sample_project")
    File.mkdir_p(env_path)
    File.write(config_path, "")

    Mix.Tasks.Gatling.Config.Set.run([
      "sample_project",
      "--foo=bar", "--baz=buz", "--QUX=qux"
    ])

    env = File.read!(config_path)

    expectation = """
    BAZ=buz
    FOO=bar
    QUX=qux
    """ |> String.trim()

    assert env == expectation

    Mix.Tasks.Gatling.Config.Set.run([
      "sample_project", "--foo=different", "--new=var"
    ])

    config_path = Gatling.Utilities.config_path("sample_project")
    env = File.read!(config_path)

    expectation = """
    BAZ=buz
    FOO=different
    NEW=var
    QUX=qux
    """ |> String.trim()

    assert env == expectation
  end

end
