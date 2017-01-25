defmodule Mix.Tasks.Gatling.Unload do
  use Mix.Task

  import Gatling.Bash

  @moduledoc """
  This is the mix task to remove a deployed Gatling project.

  __IMPORTANT_NOTE__: The `<project_name>` must match `:app` in your mix.exs

  `mix gatling.unload <project_name>` will perform:

  - Stop the service and remove the service script
  - Unconfigure and reload nginx
  - Remove the deployment directory for your mix project at `~/deployments/<project_name>`
  - Remove the git repository for your mix project
  """

  @shortdoc "Unload a deployed Gatling project"

  @type gatling_env :: %Gatling.Env{}
  @type project :: binary()

  @spec run([project]) :: nil
  def run([]) do
    project = Mix.Shell.IO.prompt("Please enter a project name:")
    unload(project)
  end

  def run([project]) do
    unload(project)
  end

  @spec unload([project]) :: nil
  @doc """
  Cleanup and remove the given project

  - Stop the service
  - Unconfigure and reload nginx
  - Remove files and directories
  """
  def unload(project) do
    Gatling.env(project)
    |> call(:stop_service)
    |> call(:remove_init_script)
    |> call(:unconfigure_nginx)
    |> call(:remove_deploy_dir)
    |> call(:remove_build_dir)
    |> call(:finish_unload)
  end

  @spec stop_service(gatling_env) :: gatling_env
  @doc "Stops the running service with `$ service <project> stop`"
  def stop_service(%Gatling.Env{}=env) do
    bash("service", ~w[#{env.project} stop])
    env
  end

  @spec remove_init_script(gatling_env) :: gatling_env
  @doc """
  Remove the system.d script from `/etc/init.d/<project>`
  """
  def remove_init_script(%Gatling.Env{}=env) do
    if File.exists?(env.etc_path) do
      bash("update-rc.d", ~w[#{env.project} remove])
      File.rm!(env.etc_path)
      bash("systemctl", ~w[daemon-reload])
    else
      log("#{env.etc_path} did not exists")
    end
    env
  end

  @spec unconfigure_nginx(gatling_env) :: gatling_env
  @doc """
  Removes the nginx.conf file for the deployed application:

  - `/etc/nginx/sites-available/<project>`
  - `/etc/nginx/sites-enabled/<project>`

  Then reload nginx's configuration.
  """
  def unconfigure_nginx(%{nginx_available_path: available_path, nginx_enabled_path: enabled_path} = env) do
    case File.exists?(enabled_path) do
      true ->
        File.rm!(enabled_path)
        bash("nginx", ~w[-s reload])

      false ->
        log("#{enabled_path} did not exist")
    end

    if File.exists?(available_path) do
      File.rm!(available_path)
    else
      log("#{available_path} did not exist")
    end

    env
  end

  @spec remove_build_dir(gatling_env) :: gatling_env
  @doc """
  Remove the projects build directory
  """
  def remove_build_dir(%Gatling.Env{}=env) do
    if File.exists?(env.build_dir) do
      File.rm_rf(env.build_dir)
    else
      log("#{env.build_dir} did not exists")
    end
    env
  end

  @spec remove_deploy_dir(gatling_env) :: gatling_env
  @doc """
  Remove the projects deployments directory
  """
  def remove_deploy_dir(%Gatling.Env{}=env) do
    if File.exists?(env.deploy_dir) do
      File.rm_rf(env.deploy_dir)
    else
      log("#{env.deploy_dir} did not exists")
    end
    env
  end

  @spec finish_unload(gatling_env) :: gatling_env
  @doc """
  If the task `mix ecto.drop` is available (it is assumed the deploying
  application has Ecto) then print a note about dropping the database.
  """
  def finish_unload(%Gatling.Env{}=env) do
    log("Finished unloading #{env.project}.")
    if (Enum.find(env.available_tasks, fn(task)-> task == "ecto.drop" end)) do
      log("The database was not affected by this, you have to drop it manually.")
    end
    env
  end

  @spec call(gatling_env, :before | :after) :: gatling_env
  @doc """
  Wrapper function for every action.

  Executes the `:before_<action>` and `:after_<action>` functions defined in `/deploy`.
  """
  def call(env, action) do
    callback(env, action, :before)
    apply(__MODULE__, action, [env])
    callback(env, action, :after)
    env
  end

  @spec callback(gatling_env, atom(), :before | :after) :: gatling_env
  @doc """
  Executes `:before` or `:after` callback function defined in  `/deploy`.
  """
  def callback(env, action, type) do
    module          = env.deploy_callback_module
    callback_action = [type, action]
                      |> Enum.map_join("_", &to_string/1)
                      |> String.to_atom()

    if function_exported?(module, callback_action, 1) do
      apply(module, callback_action, [env])
    end

    nil
  end

end
