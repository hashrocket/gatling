defmodule Gatling.Utilities do
  require EEx

  def nginx_dir do
    Application.get_env(:gatling, :nginx_dir) || "/etc/nginx"
  end

  def nginx_available_path(project) do
    Path.join([nginx_dir, "sites-available", project])
  end

  def nginx_enabled_path(project) do
    Path.join([nginx_dir, "sites-enabled", project])
  end

  def etc_dir do
    Application.get_env(:gatling, :etc_dir) || "/etc/init.d"
  end

  def etc_path(project) do
    Path.join(etc_dir, project)
  end

  def build_dir(project) do
    project   = String.strip(project)
    build_dir = Application.get_env(:gatling, :build_dir) || fn ->
      System.user_home
    end
    Path.join(build_dir.(), project)
  end

  def deploy_dir(project) do
    deploy_dir = Application.get_env(:gatling, :deploy_dir) || fn ->
      Path.join([System.user_home, "deployments"])
    end
    Path.join([deploy_dir.(), project])
  end

  def deploy_path(project) do
    Path.join [deploy_dir(project), "#{project}.tar.gz"]
  end

  def upgrade_dir(project) do
    version = version(project)
    Path.join([ deploy_dir(project), "releases", version])
  end

  def upgrade_path(project) do
    Path.join(upgrade_dir(project), "#{project}.tar.gz")
  end

  def built_release_path(project) do
    Path.join([
      build_dir(project),
      "rel",
      project,
      "releases",
      version(project),
      "#{project}.tar.gz",
    ])
  end

  def available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

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

  def git_hook_path(project) do
    [build_dir(project), ".git", "hooks", "post-update"]
    |> Path.join()
  end

  def mix_tasks(project) do
    tasks    = System.cmd("mix", ~w[help], cd: build_dir(project)) |> elem(0)
    captures = Regex.scan(~r/mix\s+([\w|.]+)/, tasks, capture: :all_but_first) 
    List.flatten(captures)
  end

  def deploy_callback_module(project) do
    deploy_callback_path = Path.join(build_dir(project), "deploy.ex")
    if File.exists? deploy_callback_path do
      Code.load_file(deploy_callback_path)
      |> List.first()
      |> elem(0)
    else
      nil
    end
  end

  # def nginx_template(domains: domains, port: port)
  EEx.function_from_file(:def, :nginx_template,
    "lib/gatling/sites_available_template.conf.eex",
    [:assigns]
  )

  # def script_template(project_name: project_name, port: port)
  EEx.function_from_file(:def, :script_template,
   "lib/gatling/init_script_template.sh.eex",
    [:assigns]
  )

  # def git_hookt_template(project_name: project_name)
  EEx.function_from_file( :def,
    :git_hook_template,
    "lib/gatling/git_hook_template.sh.eex",
    [:assigns]
  )

end
