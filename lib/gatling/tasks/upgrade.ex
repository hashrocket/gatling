defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  import Gatling.Bash
  import Mix.Tasks.Gatling.Deploy

  def run([project]) do
    upgrade(project)
  end

  def upgrade(project) do
    Gatling.env(project)
    |> mix_deps_get()
    |> mix_compile()
    |> mix_digest()
    |> mix_release()
    |> make_upgrade_dir()
    |> copy_release_to_upgrade()
    |> upgrade_service()
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


end
