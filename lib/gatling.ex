defmodule Gatling do
  import Gatling.Utilities

  def env(project, port\\nil) do
    %{
      :available_port       => port || available_port,
      :build_dir            => build_dir(project),
      :built_release_path   => built_release_path(project),
      :deploy_dir           => deploy_dir(project),
      :deploy_path          => deploy_path(project),
      :domains              => domains(project),
      :etc_dir              => etc_dir,
      :etc_path             => etc_path(project),
      :git_hook_path        => git_hook_path(project),
      :nginx_available_path => nginx_available_path(project),
      :nginx_dir            => nginx_dir,
      :nginx_enabled_path   => nginx_enabled_path(project),
      :upgrade_dir          => upgrade_dir(project),
      :upgrade_path         => upgrade_path(project),
      :version              => version(project),
    }

  end
end
