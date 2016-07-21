defmodule Mix.Tasks.Gatling.Deploy do
  require EEx

  @module """
  - Create a release of git HEAD using Exrm
  - Create a init script for the app so it will reboot on a server reboot
  - Configure Nginx go serve it
  - Start the app
  """

  def run([build_path]) do
    project       = build_path |> Path.basename()
    deploy_path   = Path.join([System.user_home, "deployments", project])
    releases_path = Path.join([build_path, "rel", project, "releases"])
    port          = available_port

    sha = System.cmd("git", ["rev-parse", "--short", "HEAD"], cd: build_path)
          |> elem(0) |> String.trim()

    System.cmd("git", ["reset", "--hard"]) |> elem(0) |> IO.write()
    System.cmd("mix", ["deps.get"], cd: build_path) |> elem(0) |> IO.write()
    System.cmd("mix", ["compile"], cd: build_path)  |> elem(0) |> IO.write()
    System.cmd("mix", ["release"], cd: build_path)  |> elem(0) |> IO.write()

    version  = File.ls!(releases_path)
             |> Enum.find(fn(path) -> Regex.match?(~r/#{sha}$/, path) end)

    release_from = Path.join([
      build_path, "rel", project, "releases", version, "#{project}.tar.gz"
    ])

    File.mkdir(deploy_path)
    IO.write "Created #{deploy_path}"

    File.cp(release_from, deploy_path)
    IO.write "Copied #{release_from} -> #{deploy_path}"

    System.cmd("tar", ["-xf", "#{project}.tar.gz", cd: deploy_path])
    IO.write "Expanded #{project}.tar.gz in #{deploy_path}"

    install_nginx_site(build_path, port)
    install_init_script(project, port)

    System.cmd("sudo", ["service", project, "start"])
  end

  def install_init_script(project_name, port) do
    file      = script_template(project_name: project_name, port: port)
    init_path = "/etc/init.d/#{project_name}.sh"
    File.write(init_path, file)
    File.chmod(init_path, 00100)
    System.cmd("update-rc.d", [project_name, "--defaults"])
  end

  def install_nginx_site(build_path, port) do
    project_name = build_path |> Path.basename()
    file         = nginx_template( domains: domains(build_path), port: port,)
    available    = "/etc/init.d/nginx/sites-available/#{project_name}"
    enabled      = "/etc/init.d/nginx/sites-enabled/#{project_name}"

    File.write(available, file)
    File.ln_s(available, enabled)
    System.cmd("nginx", ["-s", "reload"])
  end

  def domains(build_path) do
    Path.join(build_path, "domains")
    |> File.read!()
    |> String.split(~r/,?\s/, trim: true)
    |> Enum.join(" ")
  end

  def available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

  EEx.function_from_file( :def,
    :script_template,
    __DIR__ |> Path.dirname |> Path.join("init_script_template.sh.eex"),
    [:assigns]
  )

  EEx.function_from_file( :def,
    :nginx_template,
    __DIR__ |> Path.dirname |> Path.join("sites_available_template.conf.eex"),
    [:assigns]
  )


end
