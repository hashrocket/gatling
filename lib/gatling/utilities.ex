defmodule Gatling.Utilities do
  require EEx

  def nginx_path do
    Application.get_env(:gatling, :nginx_path) || "/etc/nginx"
  end

  def etc_path do
    Application.get_env(:gatling, :etc_path) || "/etc/init.d"
  end

  def build_path(project_name) do
    project   = String.strip(project_name)
    build_dir = Application.get_env(:gatling, :build_path) || fn -> System.user_home end
    Path.join(build_dir.(), project)
  end

  def deploy_dir(project) do
    deploy_path = Application.get_env(:gatling, :deploy_path) || fn -> Path.join([System.user_home, "deployments"]) end
    Path.join([deploy_path.(), project])
  end

  def upgrade_dir(project, version) do
    Path.join([
      deploy_dir(project),
      "releases",
      version,
    ])
  end

  def available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

  def version(build_path) do
    path = Path.join([build_path, "mix.exs"])
    [{mix_project, _}] = Code.load_file(path)
    mix_project.project[:version]
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
