defmodule Mix.Tasks.Gatling.Deploy do
  use Mix.Task

  import Gatling.Bash

  @moduledoc """
  - Create a release of git HEAD using Exrm
  - Create a init script for the app so it will reboot on a server reboot
  - Configure Nginx go serve it
  - Start the app
  """

  @shortdoc "Create an exrm release of the given project and deploy it"

  def run([project]) do
    deploy(project)
  end

  def deploy(project) do
    Gatling.env(project, port: :find)
    |> call(:mix_deps_get)
    |> call(:mix_compile)
    |> call(:mix_digest)
    |> call(:mix_release)
    |> call(:make_deploy_dir)
    |> call(:copy_release_to_deploy)
    |> call(:expand_release)
    |> call(:install_init_script)
    |> call(:mix_ecto_setup)
    |> call(:start_service)
    |> call(:configure_nginx)
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

  def make_deploy_dir(env) do
    File.mkdir_p!(env.deploy_dir)
    env
  end

  def copy_release_to_deploy(env) do
    File.cp!(env.built_release_path, env.deploy_path)
    env
  end

  def expand_release(env) do
    bash("tar", ~w[-xf #{env.project}.tar.gz], cd: env.deploy_dir )
    env
  end

  def install_init_script(env) do
    File.write!(env.etc_path, env.script_template)
    File.chmod!(env.etc_path, 0o777)
    bash("update-rc.d", ~w[#{env.project} defaults])
    env
  end

  def configure_nginx(%{nginx_available_path: available, nginx_enabled_path: enabled} = env) do
    if env.domains do
      File.write!(available, env.nginx_template)
      unless File.exists?(enabled), do: File.ln_s(available, enabled)
      bash("nginx", ~w[-s reload])
    end
    env
  end

  def mix_ecto_setup(env) do
    if Enum.find(env.available_tasks, fn(task)-> task == "ecto.create" end) do
      bash("mix", ~w[do ecto.create, ecto.migrate, run priv/repo/seeds.exs], cd: env.build_dir)
    end
    env
  end

  def start_service(env) do
    bash("service", ~w[#{env.project} start], env: [{"PORT", to_string(env.available_port)}])
    env
  end

  def call(env, action) do
    callback(env, action, :before)
    apply(__MODULE__, action, [env])
    callback(env, action, :after)
    env
  end

  def callback(env, type, action) do
    module          = env.deploy_callback_module
    callback_action = callback_action(type, action)

    if function_exported?(module, callback_action, 1) do
      apply(module, callback_action, [env])
    end

    nil
  end

  def callback_action(type, action) do
    [type, action]
    |> Enum.map(&to_string/1)
    |> Enum.join("_")
    |> String.to_atom()
  end

end
