defmodule Gatling.Utilities do
  require EEx

  @moduledoc """
  Used by Gatling to generate the `%Gatling.Env{}`
  """
  @type project :: binary()

  @spec nginx_dir() :: binary()
  @doc """
  Default system path to nginx

  `/etc/nginx`
  """
  def nginx_dir do
    Application.get_env(:gatling, :nginx_dir) || "/etc/nginx"
  end

  @spec nginx_available_path(project) :: binary()
  @doc """
  Default system path to nginx sites-available

  `/etc/nginx/sites-available/`
  """
  def nginx_available_path(project) do
    Path.join([nginx_dir(), "sites-available", project])
  end

  @spec nginx_config(project) :: binary()
  @doc """
  Nginx Configuration file used to override the default `nginx_template`.

  Add to your project root in`./nginx.conf`. Must be a valid config file.

  __NOTE__: If you plan on using you own `nginx.conf`, make sure to manually
  set the `port` of your application to match your `nginx.conf`. Do not use the
  `PORT` environment variable in your application config as the port your
  application is running on will not match that which nginx is proxying to.
  """
  def nginx_config(project) do
    nginx_config_path = Path.join(build_dir(project), "nginx.conf")
    case File.read(nginx_config_path) do
      {:ok, config_file} -> config_file
      {:error, _} -> nil
    end
  end

  @spec nginx_enabled_path(project) :: binary()
  @doc """
  Default system path to nginx sites-enabled

  `/etc/nginx/sites-enabeld`
  """
  def nginx_enabled_path(project) do
    Path.join([nginx_dir(), "sites-enabled", project])
  end

  @spec etc_dir() :: binary()
  @doc """
  Default system path to linux init.d scripts

  `/etc/init.d/`
  """
  def etc_dir do
    Application.get_env(:gatling, :etc_dir) || "/etc/init.d"
  end

  @spec etc_path(project) :: binary()
  @doc """
  Path to project's init.d script

  `/etc/init.d/<project>`
  """
  def etc_path(project) do
    Path.join(etc_dir(), project)
  end

  @spec build_dir(project) :: binary()
  @doc """
  Path to the git repo for given project

  This the build steps heppen here:
  - Install dependencies
  - Compile
  - Generate release

  `~/<project>/`
  """
  def build_dir(project) do
    project   = String.strip(project)
    build_dir = Application.get_env(:gatling, :build_dir) || fn ->
      System.user_home
    end
    Path.join(build_dir.(), project)
  end

  @spec release_config_path(project) :: binary()
  @doc """
  Path to Distillery's config.exs file which is generated when calling `mix release.init`

  `~/<project>/rel/config/exs`
  """
  def release_config_path(project) do
    build_dir = Application.get_env(:gatling, :build_dir) || fn ->
      System.user_home
    end
    Path.join([build_dir.(), project, "rel", "config.exs"])
  end


  @spec releases(project) :: list(binary())
  @doc """
  List all releases found in ~/<project>/rel/<project>/releases
  """
  def releases(project) do
    path = Path.join([build_dir(project), "rel", project, "releases"])
    if File.exists?(path) do
      path
      |> File.ls!()
      |> Enum.filter(fn item -> File.dir?(Path.join(path, item)) end)
      |> Enum.sort(&semver_order/2)
    else
      []
    end
  end

  defp semver_order(a, b) do
    case Version.compare(a, b) do
      :gt -> false
      :lt -> true
      :eq -> true
    end
  end

  @spec deploy_dir(project) :: binary()
  @doc """
  Directory to running applications

  `~/deployments/`
  """
  def deploy_dir(project) do
    deploy_dir = Application.get_env(:gatling, :deploy_dir) || fn ->
      Path.join([System.user_home, "deployments"])
    end
    Path.join([deploy_dir.(), project])
  end

  @spec deploy_path(project) :: binary()
  @doc """
  Path to deployed project

  `~/deployments/<project>`
  """
  def deploy_path(project) do
    Path.join [deploy_dir(project), "#{project}.tar.gz"]
  end

  @spec config_path(project) :: binary()
  @doc """
  Path to deployed project's .env file

  `~/deployments/<project>/.env`
  """
  def config_path(project) do
    Path.join [deploy_dir(project), ".env"]
  end

  @spec upgrade_dir(project) :: binary()
  @doc """
  Path to put the "upgrade" releases

  `~/deployments/<project>/releases/<version>`
  """
  def upgrade_dir(project) do
    version = version(project)
    Path.join([ deploy_dir(project), "releases", version])
  end

  @spec upgrade_path(project) :: binary()
  @doc """
  Path to put the "upgrade" release's .tar file

  `~/deployments/<project>/releases/<version>/<project>.tar.gx`
  """
  def upgrade_path(project) do
    Path.join(upgrade_dir(project), "#{project}.tar.gz")
  end

  @spec built_release_path(project) :: binary()
  @doc """
  Location of the release after it's been generated. Located inside the `build_dir`

  `~/<project>/_build/prod/rel/<project>/releases/<version>/<project>.tar.gz`
  """
  def built_release_path(project) do
    Path.join([
      build_dir(project),
      "_build",
      "prod",
      "rel",
      project,
      "releases",
      version(project),
      "#{project}.tar.gz",
    ])
  end

  @spec available_port() :: integer()
  @doc """
  Find an open port
  """
  def available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

  @spec version(project) :: binary()
  @doc """
  Find the version number of the project being deployed
  """
  def version(project) do
    build_dir    = build_dir(project)
    path         = Path.join(build_dir, "mix.exs")
    file         = File.read!(path)
    module_regex = ~r/defmodule\s+(?<module>[\w|\.]+)/
    module_name  = Regex.named_captures(module_regex, file)["module"]
    module       = Module.concat([module_name])

    File.cd! build_dir, fn ->
      module = case Code.ensure_loaded(module) do
        {:error, _} -> Code.eval_string(file) |> elem(0) |> elem(1)
        {:module, _} -> module
      end
      module.project[:version]
    end
  end

  @spec domains(project) :: binary()
  @doc """
  Read the projects `./domains` file to be used when configuring nginx
  """
  def domains(project) do
    domain_path = Path.join(build_dir(project), "domains")
    case File.read(domain_path) do
      {:ok, txt} -> txt |> String.split(~r/,?\s/, trim: true) |> Enum.join(" ")
      {:error, _} -> Gatling.Bash.log("""
      No 'domains' file detected. If you want to auto-configure nginx,
      Add a file called 'domains' to the root of your project. See
      "https://github.com/hashrocket/gatling/tree/master/test/sample_project"
      for an example.
      """)
    end
  end

  @spec domains(project) :: binary()
  @doc """
  Path to the projects git post-update hook

  `~/<project>/.git/hooks/post-update`
  """
  def git_hook_path(project) do
    [build_dir(project), ".git", "hooks", "post-update"]
    |> Path.join()
  end

  @spec mix_tasks(project) :: list(binary())
  @doc """
  List of all available mix tasks that can be run by the given project
  """
  def mix_tasks(project) do
    tasks    = System.cmd("mix", ~w[help], cd: build_dir(project)) |> elem(0)
    captures = Regex.scan(~r/mix\s+([\w|.]+)/, tasks, capture: :all_but_first)
    List.flatten(captures)
  end

  @spec callback_module(project, [task: :upgrade|:deploy]) :: module()
  @doc """
  Module defined in the project under `./upgrade.exs` or `./deploy.exs`
  """
  def callback_module(project, [task: task_name]) do
    callback_path = Path.join(build_dir(project), "#{task_name}.exs")
    if File.exists? callback_path do
      Code.load_file(callback_path) |> List.first() |> elem(0)
    else
      nil
    end
  end

  @spec nginx_template([domains: list(), port: integer()]) :: binary()
  @doc """
  Template used to configure nginx

  ```eex
  #{File.read!("lib/gatling/sites_available_template.conf.eex")}
  ```
  """
  # def nginx_template(domains: domains, port: port)
  EEx.function_from_file(:def, :nginx_template,
  "lib/gatling/sites_available_template.conf.eex",
  [:assigns]
  )

  @spec script_template([project_name: project, port: integer()]) :: binary()
  @doc """
  Template used for the init.d script.

  If/when the server starts, this will boot your project

  ```eex
  #{File.read!("lib/gatling/init_script_template.sh.eex")}
  ```
  """
  # def script_template(project_name: project_name, port: port)
  EEx.function_from_file(:def, :script_template,
  "lib/gatling/init_script_template.sh.eex",
  [:assigns]
  )

  @spec git_hook_template([domains: list(), port: integer()]) :: binary()
  @doc """
  Template used when loading a new project for the git `post-update` hook

  ```txt
  #{File.read!("lib/gatling/git_hook_template.sh.eex")}
  ```
  """
  # def git_hook_template(project_name: project_name)
  EEx.function_from_file( :def,
  :git_hook_template,
  "lib/gatling/git_hook_template.sh.eex",
  [:assigns]
  )

end
