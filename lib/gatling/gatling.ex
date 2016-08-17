defmodule Gatling do
  import Gatling.Utilities

  def env(project), do: env(project, port: nil)
  def env(project, [port: port]) do
    port = if port == :find, do: available_port, else: port
    domains = domains(project)
    %{
      :project                 => project,
      :available_port          => port,
      :build_dir               => build_dir(project),
      :built_release_path      => built_release_path(project),
      :deploy_dir              => deploy_dir(project),
      :deploy_path             => deploy_path(project),
      :domains                 => domains,
      :etc_dir                 => etc_dir,
      :etc_path                => etc_path(project),
      :git_hook_path           => git_hook_path(project),
      :nginx_available_path    => nginx_available_path(project),
      :nginx_dir               => nginx_dir,
      :nginx_enabled_path      => nginx_enabled_path(project),
      :upgrade_dir             => upgrade_dir(project),
      :upgrade_path            => upgrade_path(project),
      :version                 => version(project),
      :script_template         => script_template(project_name: project, port: port),
      :nginx_template          => nginx_template(domains: domains, port: port),
      :available_tasks         => mix_tasks(project),
      :deploy_callback_module  => callback_module(project, task: "deploy"),
      :upgrade_callback_module => callback_module(project, task: "upgrade"),
    }

  end
end
