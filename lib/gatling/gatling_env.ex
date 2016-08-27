defmodule Gatling.Env do
  @moduledoc """
  The %Gatling.Env{} struct
  """
  defstruct ~w[
      available_port
      available_tasks
      build_dir
      built_release_path
      deploy_callback_module
      deploy_dir
      deploy_path
      domains
      etc_dir
      etc_path
      git_hook_path
      nginx_available_path
      nginx_dir
      nginx_enabled_path
      nginx_template
      project
      script_template
      upgrade_callback_module
      upgrade_dir
      upgrade_path
      version
    ]a
end
