defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  import Gatling.Bash

  def run([project]) do
    upgrade(project)
  end

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

  def mix_deps_get(env) do
    bash("mix", ~w[deps.get], cd: env.build_dir)
    env
  end

  def mix_compile(env) do
    bash("mix", ~w[compile --force], cd: env.build_dir)
    env
  end

  def mix_digest(env) do
    bash("mix", ~w[phoenix.digest -o public/static], cd: env.build_dir)
    env
  end

  def mix_release(env) do
    bash("mix", ~w[release --no-confirm-missing],cd: env.build_dir)
    env
  end

  def make_upgrade_dir(env) do
    File.mkdir_p!(env.upgrade_dir)
    env
  end

  def copy_release_to_upgrade(env) do
    File.cp!(env.built_release_path, env.upgrade_path)
    env
  end

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
