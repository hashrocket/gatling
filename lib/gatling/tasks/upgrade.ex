defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  import Gatling.Bash

  @moduledoc """
  - Create a release of the last commit
  - Perform a hot upgrade of the currently running application
  """

  @shortdoc "Hot upgrade the given project"

  @type gatling_env :: %Gatling.Env{}
  @type project :: binary()

  @spec run([project]) :: gatling_env
  def run([project]) do
    upgrade(project)
  end

  @spec upgrade([project]) :: gatling_env
  @doc """
  The main function of `Mix.Tasks.Gatling.Upgrade`
  """
  def upgrade(project) do
    Gatling.env(project)
    |> call(:mix_deps_get)
    |> call(:mix_compile)
    |> call(:mix_digest)
    |> call(:mix_release_init)
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
    bash("mix", ~w[phoenix.digest], cd: env.build_dir)
    env
  end

  @spec mix_release_init(gatling_env) :: gatling_env
  @doc """
  Look look for `/rel/config.exs`
  If it doesn't exist, run `mix release.init`
  """
  def mix_release_init(%Gatling.Env{}=env) do
    if File.exists?(env.release_config_path) do
      Gatling.Bash.log("#{env.release_config_path} found")
    else
      bash("mix", ~w[release.init --no-doc],cd: env.build_dir)
    end
    env
  end

  @spec mix_release(gatling_env) :: gatling_env
  @doc """
  Generate a release of the deploying project with [Distillery](http://github.com/bitwalker/distillery)
  """
  def mix_release(env) do
    last_release = List.last(env.releases)
    bash("mix", ~w[release --upgrade --upfrom=#{last_release} --warnings-as-errors --env=prod], cd: env.build_dir)
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
  Leverage Distillery to perform a hot upgrade of the running project
  """
  def upgrade_service(env) do
    bash("service", ~w[#{env.project} upgrade #{env.version}], [])
    env
  end

  @spec call(gatling_env, :before | :after) :: gatling_env
  @doc """
  Wrapper function for every action.

  Executes the `:before_<action>` and `:after_<action>` functions defined in `/upgrade`.
  """
  def call(env, action) do
    callback(env, action, :before)
    apply(__MODULE__, action, [env])
    callback(env, action, :after)
    env
  end

  @spec callback(gatling_env, atom(), :before | :after) :: gatling_env
  @doc """
  Executes `:before` or `:after` callback function defined in  `/upgrade`.
  """
  def callback(env, action, type) do
    module          = env.upgrade_callback_module
    callback_action = [type, action]
                      |> Enum.map_join("_", &to_string/1)
                      |> String.to_atom()

    if function_exported?(module, callback_action, 1) do
      apply(module, callback_action, [env])
    end

    nil
  end

end
