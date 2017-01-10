defmodule Gatling do
  import Gatling.Utilities

  @type project :: binary()
  @type gatling_env :: %Gatling.Env{}

  @doc """
  Build all the information needed to perform a gatling deploy.
  """
  @spec env(project, [{:atom, integer()}]) :: gatling_env

  def env(project, [port: port] \\ [port: nil]) do
    port = if port == :find, do: available_port(), else: port
    domains = domains(project)
    %Gatling.Env{
      :available_port          => port,
      :available_tasks         => mix_tasks(project),
      :build_dir               => build_dir(project),
      :built_release_path      => built_release_path(project),
      :deploy_callback_module  => callback_module(project, task: "deploy"),
      :deploy_dir              => deploy_dir(project),
      :deploy_path             => deploy_path(project),
      :domains                 => domains,
      :etc_dir                 => etc_dir(),
      :etc_path                => etc_path(project),
      :git_hook_path           => git_hook_path(project),
      :nginx_available_path    => nginx_available_path(project),
      :nginx_dir               => nginx_dir(),
      :nginx_enabled_path      => nginx_enabled_path(project),
      :nginx_template          => nginx_template(domains: domains, port: port),
      :project                 => project,
      :releases                => releases(project),
      :release_config_path     => release_config_path(project),
      :script_template         => script_template(project_name: project, port: port),
      :upgrade_callback_module => callback_module(project, task: "upgrade"),
      :upgrade_dir             => upgrade_dir(project),
      :upgrade_path            => upgrade_path(project),
      :version                 => version(project),
    }

  end
end
