defmodule Mix.Tasks.Gatling.Deploy do
  use Mix.Task

  import Gatling.Bash

  @moduledoc """
  - Create a release of the last commit
  - Create a init script for the app so it will reboot on a server reboot
  - Start the app
  - Configure Nginx go serve it
  """

  @shortdoc "Create a Distillery release of the given project and deploy it"

  @type gatling_env :: %Gatling.Env{}
  @type project :: binary()

  @spec run([project]) :: gatling_env
  def run([project]) do
    deploy(project)
  end

  @spec deploy([project]) :: gatling_env
  @doc """
  The main function of `Mix.Tasks.Gatling.Deploy`
  """
  def deploy(project) do
    Gatling.env(project, port: :find)
    |> call(:mix_deps_get)
    |> call(:mix_compile)
    |> call(:mix_digest)
    |> call(:mix_release_init)
    |> call(:mix_release)
    |> call(:make_deploy_dir)
    |> call(:copy_release_to_deploy)
    |> call(:expand_release)
    |> call(:install_init_script)
    |> call(:mix_ecto_setup)
    |> call(:start_service)
    |> call(:configure_nginx)
  end

  @spec mix_deps_get(gatling_env) :: gatling_env
  @doc """
  Run the mix task `mix deps.get` in the project being deployed
  """
  def mix_deps_get(%Gatling.Env{}=env) do
    bash("mix", ~w[deps.get], cd: env.build_dir)
    env
  end

  @spec mix_compile(gatling_env) :: gatling_env
  @doc """
  Compile the application being deployed
  """
  def mix_compile(%Gatling.Env{}=env) do
    bash("mix", ~w[compile --force], cd: env.build_dir)
    env
  end

  @spec mix_digest(gatling_env) :: gatling_env
  @doc """
  Create static phoenix files if the project is a phoenix project
  """
  def mix_digest(%Gatling.Env{}=env) do
    if (Enum.find(env.available_tasks, fn(task)-> task == "phoenix.digest" end)) do
      bash("mix", ~w[phoenix.digest], cd: env.build_dir)
    end
    env
  end

  @spec mix_release_init(gatling_env) :: gatling_env
  @doc """
  Look look for `/rel/config.exs`
  If it doesn't exist, run `mix release.init`
  """
  def mix_release_init(%Gatling.Env{}=env) do
    if File.exists?(env.release_config_path) do
      log("#{env.release_config_path} found")
    else
      bash("mix", ~w[release.init --no-doc], cd: env.build_dir)
    end
    env
  end

  @spec mix_release(gatling_env) :: gatling_env
  @doc """
  Generate a release of the deploying project with [Distillery](http://github.com/bitwalker/distillery)
  """
  def mix_release(%Gatling.Env{}=env) do
    bash("mix", ~w[release --warnings-as-errors --env=prod], cd: env.build_dir)
    env
  end

  @spec make_deploy_dir(gatling_env) :: gatling_env
  @doc """
  Create a directory in the build path of the `project`
  """
  def make_deploy_dir(%Gatling.Env{}=env) do
    File.mkdir_p(env.deploy_dir)
    env
  end

  @spec copy_release_to_deploy(gatling_env) :: gatling_env
  @doc """
  Copy the generated release into the deployment directory
  """
  def copy_release_to_deploy(%Gatling.Env{}=env) do
    File.cp!(env.built_release_path, env.deploy_path)
    env
  end

  @spec expand_release(gatling_env) :: gatling_env
  @doc """
  Expand the generated Distillery release
  """
  def expand_release(%Gatling.Env{}=env) do
    bash("tar", ~w[-xf #{env.project}.tar.gz], cd: env.deploy_dir)
    env
  end

  @spec install_init_script(gatling_env) :: gatling_env
  @doc """
  Create a system.d script and install it in `/etc/init.d/<project>`
  If the server restarts, the deploying project will boot automatically.

  Also makes the following comands (created by distillery) available in your deployment server:

  ```bash
  $ sudo --preserve-env service <project> start|start_boot <file>|foreground|stop|restart|reboot|ping|rpc <m> <f> [<a>]|console|console_clean|console_boot <file>|attach|remote_console|upgrade|escript|command <m> <f> <args>
  ```
  """
  def install_init_script(%Gatling.Env{}=env) do
    if File.exists?(env.etc_path) do
      log("#{env.etc_path} already exists")
    else
      File.write!(env.etc_path, env.script_template)
      File.chmod!(env.etc_path, 0o777)
      bash("update-rc.d", ~w[#{env.project} defaults])
    end
    env
  end

  @spec configure_nginx(gatling_env) :: gatling_env
  @doc """
  Create an nginx.cong file to configure a reverse proxy to the
  deploying application. Install the file in:

  `/etc/nginx/sites-available/<project>`

  and symlink it in:

  - `/etc/nginx/sites-enabled/<project>`

  Then reload nginx's configuration
  __Note:__ if you already have an nginx.conf file in
  `/etc/nginx/sites-available/<project>` this will not run.
  """
  def configure_nginx(%{nginx_available_path: available, nginx_enabled_path: enabled} = env) do
    if env.domains do
      if File.exists?(enabled) do
        log("#{available} found")
      else
        File.write!(available, env.nginx_template)
        File.ln_s(available, enabled)
        bash("nginx", ~w[-s reload])
      end
    end
    env
  end

  @spec mix_ecto_setup(gatling_env) :: gatling_env
  @doc """
  If the task `mix ecto.setup` is available (it is assumed the deploying
  application has Ecto) then create the database, run migrations,
  and run the seeds file.
  """
  def mix_ecto_setup(%Gatling.Env{}=env) do
    if (Enum.find(env.available_tasks, fn(task)-> task == "ecto.setup" end)) do
      # Provide PORT env variable for ecto.setup as it is needed for the seeds to run.
      bash("mix", ~w[ecto.setup], cd: env.build_dir, env: [{"PORT", to_string(env.available_port)}])
    end
    env
  end

  @spec start_service(gatling_env) :: gatling_env
  @doc "Start the newly created service with `$ service <project> start`"
  def start_service(%Gatling.Env{}=env) do
    bash("service", ~w[#{env.project} start])
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
