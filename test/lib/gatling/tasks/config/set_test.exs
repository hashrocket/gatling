defmodule Gatling.Tasks.ConfigTest do
  use ExUnit.Case, async: true

  test "Setting config" do
    on_exit fn-> File.rm_rf("test/root") end

    env_path = Gatling.Utilities.deploy_dir("sample_project")
    config_path = Gatling.Utilities.config_path("sample_project")
    File.mkdir_p(env_path)
    File.write(config_path, "")

    options = OptionParser.to_argv([foo: "bar", baz: "buz", qux: "qux"])
    command = ["sample_project"] ++ options

    Mix.Tasks.Gatling.Config.Set.run(command)

    env = File.read!(config_path)

    expectation = """
    BAZ=buz
    FOO=bar
    QUX=qux
    """ |> String.trim()

    assert env == expectation

    options = OptionParser.to_argv([foo: "different", new: "var"])
    command = ["sample_project"] ++ options

    Mix.Tasks.Gatling.Config.Set.run(command)

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
