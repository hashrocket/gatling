defmodule Mix.Tasks.Gatling.Deploy do
  @module """
  - Copy most recent deploy into deploy directory found at %{System.user_home}/deployed/<project_name>
  - If this is an initial deploy:
  - create a init script for the app
  - add app with the domains to nginx configuration
  - start the service
  - If this is an upgrade
  - perform hot upgrade to the running application
  """

  @build_location System.user_home
  @deploy_location "/app"

  EEx.function_from_file( :def,
    :script_template,
    Path.join([__DIR__, "../init_script_template.sh.eex"]),
    [:assigns]
  )

  EEx.function_from_file( :def,
    :nginx_template,
    Path.join([__DIR__, "../nginx.conf.eex"]),
    [:assigns]
  )

  def run([project]) do
    unless File.exists?(@deploy_location), do: File.mk_dir(@deploy_location)
    port = available_port
    copy_release_to_deploy(project)
    install_nginx_site(project, port)
    install_init_script(project, port)
  end

  def copy_release_to_deploy(project) do
    latest_release_path = latest_release_path(project)
    File.cp_r(latest_release_path, @deploy_location)
  end

  def latest_release(project) do
    mix_path           = Path.join([@build_location, project,  "mix.exs"])
    [{application, _}] = Code.load_file(mix_path)
    version            = application.project[:version]

    Path.join([@build_location, project, "rel", project, "releases", version ])
  end

  def install_init_script(project_name, port) do
    file = script_template(project_name: project_name, port: port)
    File.write("~/#{project_name}.sh", file)
    System.cmd("update-rc.d", [project_name, "--defaults"])
  end

  def install_nginx_site(project_name, port) do
    file = nginx_template(
      domains: domains,
      project_name: project_name,
      port: port,
    )

    available = "/etc/init.d/nginx/sites-available/#{project_name}"
    enabled   = "/etc/init.d/nginx/sites-enabled/#{project_name}"

    File.write(available, file)
    File.ln_s(available, enabled)
    System.cmd("nginx", ["-s", "reload"]
  end

  def domains do
    domains_path = Path.join([@build_location, project_name, "domains"])
    case File.read(domains_path)} do
      {:ok, string} ->
        string
        |> String.split(~r/,?\s/, trim: true)
        |> Enum.join(" ")
      {:error, _} -> ""
    end
  end

  def available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

end
