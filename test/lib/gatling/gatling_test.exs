defmodule GatlingTest do
  use ExUnit.Case

  setup do
    build_dir = Gatling.Utilities.build_dir("sample_project")
    File.mkdir_p(build_dir)
    File.cp_r("test/sample_project", build_dir)

    on_exit fn ->
      File.rm_rf("test/root")
      File.rm_rf("test/sample_project/rel")
    end

    IO.puts("")

    :ok
  end

  def matches?(string, assertion) do
    regex = ~r/#{assertion}/
    assert(Regex.match?(regex, string), "#{string} \n|doesn't match|\n#{assertion}")
  end

  test ".env" do
    domains = Gatling.Utilities.domains("sample_project")
    env = Gatling.env("sample_project", port: 4001)

    #Write the env to ./env.example.exs for documentation
    example_file = inspect(env, pretty: true)
                    |> String.replace(~r/\"\s*(.+\/test)/, "\"")
    File.write("env.example.exs", example_file)

    assert env.available_port          == 4001
    assert env.project                 == "sample_project"
    assert env.domains                 == domains
    assert env.script_template         == Gatling.Utilities.script_template(project_name: "sample_project", port: 4001)
    assert env.nginx_template          == Gatling.Utilities.nginx_template(domains: domains, port: 4001)
    assert env.available_tasks         == Gatling.Utilities.mix_tasks("sample_project")
    assert env.version                 == "0.0.1470406670"
    assert env.deploy_callback_module  == SampleProject.DeployCallbacks # test/sample_project/deploy.ex
    assert env.upgrade_callback_module == SampleProject.UpgradeCallbacks # test/sample_project/upgrade.ex

    env.build_dir            |>  matches?("/root/home/ubuntu/sample_project")
    env.built_release_path   |>  matches?("/root/home/ubuntu/sample_project/rel/sample_project/releases/0.0.1470406670/sample_project.tar.gz")
    env.deploy_dir           |>  matches?("/root/home/ubuntu/deployments/sample_project")
    env.deploy_path          |>  matches?("/root/home/ubuntu/deployments/sample_project/sample_project.tar.gz")
    env.etc_dir              |>  matches?("/root/etc/init.d")
    env.etc_path             |>  matches?("/root/etc/init.d/sample_project")
    env.git_hook_path        |>  matches?("/root/home/ubuntu/sample_project/.git/hooks/post-update")
    env.nginx_available_path |>  matches?("/root/etc/nginx/sites-available/sample_project")
    env.nginx_dir            |>  matches?("/root/etc/nginx")
    env.nginx_enabled_path   |>  matches?("/root/etc/nginx/sites-enabled/sample_project")
    env.upgrade_dir          |>  matches?("/root/home/ubuntu/deployments/sample_project/releases/0.0.1470406670")
    env.upgrade_path         |>  matches?("/root/home/ubuntu/deployments/sample_project/releases/0.0.1470406670/sample_project.tar.gz")

  end

end
