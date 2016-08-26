defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  import Gatling.Bash

  @moduledoc """
  - Create a release of the last commit using EXRM
  - Perform a hot upgrade of the currently running application
  """

  @shortdoc "Hot upgrade the given project"

  @type gatling_env :: %Gatling.Env{}
  @type project_name :: binary()


  @spec run([project_name]) :: gatling_env
  def run([project]) do
    upgrade(project)
  end

  @spec upgrade([project_name]) :: gatling_env
  @doc """
  The main function of `Mix.Tasks.Gatling.Upgrade`
  """
  def upgrade(project) do
    Gatling.env(project)
    |> call(:mix_deps_get)
    |> call(:mix_compile)
    |> call(:mix_digest)
    |> call(:mix_release)
    |> call(:make_upgrade_dir)
    |> call(:copy_release_to_upgrade)
    |> call(:upgrade_service)
  end

  @spec mix_deps_get(gatling_env) :: gatling_env
  @doc """
  Run the mix task `mix deps.get` in the project being deployed
  """
  def mix_deps_get(env) do
    bash("mix", ~w[deps.get], cd: env.build_dir)
    env
  end

  @spec mix_compile(gatling_env) :: gatling_env
  @doc """
  Compile the application being deployed
  """
  def mix_compile(env) do
    bash("mix", ~w[compile --force], cd: env.build_dir)
    env
  end

  @spec mix_digest(gatling_env) :: gatling_env
  @doc """
  Create static phoenix files
  """
  def mix_digest(env) do
    bash("mix", ~w[phoenix.digest -o public/static], cd: env.build_dir)
    env
  end

  @spec mix_release(gatling_env) :: gatling_env
  @doc """
  Generate a release of the deploying project with [exrm](http://github.com/bitwalker/exrm)
  """
  def mix_release(env) do
    bash("mix", ~w[release --no-confirm-missing],cd: env.build_dir)
    env
  end

  @spec make_upgrade_dir(gatling_env) :: gatling_env
  @doc """
  Create a directory of the current release in the build path of the `project`
  """
  def make_upgrade_dir(env) do
    File.mkdir_p!(env.upgrade_dir)
    env
  end

  @spec copy_release_to_upgrade(gatling_env) :: gatling_env
  @doc """
  Copy the generated release into the releases directory for the deploying project
  """
  def copy_release_to_upgrade(env) do
    File.cp!(env.built_release_path, env.upgrade_path)
    env
  end

  @spec upgrade_service(gatling_env) :: gatling_env
  @doc """
  Leverage Exrm to perform a hot upgrad of the running project
  """
  def upgrade_service(env) do
    bash("service", ~w[#{env.project} upgrade #{env.version}], [])
    env
  end

  defp call(env, action) do
    callback(env, action, :before)
    apply(__MODULE__, action, [env])
    callback(env, action, :after)
    env
  end

  defp callback(env, action, type) do
    module          = env.upgrade_callback_module
    callback_action = [type, action]
                      |> Enum.map(&to_string/1)
                      |> Enum.join("_")
                      |> String.to_atom()

    if function_exported?(module, callback_action, 1) do
      apply(module, callback_action, [env])
    end

    nil
  end

end
