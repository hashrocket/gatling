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

  test ".env" do
    domains = Gatling.Utilities.domains("sample_project")
    env = Gatling.env("sample_project", port: 4001)
    assert env ==  %{
     :project              => "sample_project",
     :available_port       => 4001,
     :build_dir            => "/Users/dev/hashrocket/gatling/test/root/home/ubuntu/sample_project",
     :built_release_path   => "/Users/dev/hashrocket/gatling/test/root/home/ubuntu/sample_project/rel/sample_project/releases/0.0.1470406670/sample_project.tar.gz",
     :deploy_dir           => "/Users/dev/hashrocket/gatling/test/root/home/ubuntu/deployments/sample_project",
     :deploy_path          => "/Users/dev/hashrocket/gatling/test/root/home/ubuntu/deployments/sample_project/sample_project.tar.gz",
     :domains              => "www.example.com sample_project.hashrocket.com api.example.com",
     :etc_dir              => "/Users/dev/hashrocket/gatling/test/root/etc/init.d",
     :etc_path             => "/Users/dev/hashrocket/gatling/test/root/etc/init.d/sample_project",
     :git_hook_path        => "/Users/dev/hashrocket/gatling/test/root/home/ubuntu/sample_project/.git/hooks/post-update",
     :nginx_available_path => "/Users/dev/hashrocket/gatling/test/root/etc/nginx/sites-available/sample_project",
     :nginx_dir            => "/Users/dev/hashrocket/gatling/test/root/etc/nginx",
     :nginx_enabled_path   => "/Users/dev/hashrocket/gatling/test/root/etc/nginx/sites-enabled/sample_project",
     :upgrade_dir          => "/Users/dev/hashrocket/gatling/test/root/home/ubuntu/deployments/sample_project/releases/0.0.1470406670",
     :upgrade_path         => "/Users/dev/hashrocket/gatling/test/root/home/ubuntu/deployments/sample_project/releases/0.0.1470406670/sample_project.tar.gz",
     :version              => "0.0.1470406670",
     :script_template      => Gatling.Utilities.script_template(project_name: "sample_project", port: 4001),
     :nginx_template       => Gatling.Utilities.nginx_template(domains: domains, port: 4001),
   }
  end

end
