defmodule Mix.Tasks.Gatling.Deploy do
  require EEx

  import Gatling.Bash, only: [bash: 3, bash: 2]

  @module """
  - Create a release of git HEAD using Exrm
  - Create a init script for the app so it will reboot on a server reboot
  - Configure Nginx go serve it
  - Start the app
  """

  def run([]) do
    build_path = Mix.Shell.IO.prompt("Please enter the path to your project:") 
                  |> String.trim()
    deploy(build_path)
  end

  def run([build_path]) do
    deploy(build_path)
  end

  def deploy(build_path) do
    project      = Path.basename(build_path)
    deploy_path  = Path.join([System.user_home, "deployments", project])
    port         = available_port

    git_reset_hard(build_path)
    mix_deps_get(build_path)
    mix_compile(build_path)
    make_deploy_dir(deploy_path)

    release_version = mix_release(build_path)
    copy_release_to_deploy(build_path, deploy_path, release_version)

    expand_release(project, deploy_path)
    install_nginx_site(build_path, port)
    install_init_script(project, port)
    start_service(project, port)
  end

  def git_reset_hard(build_path) do
    bash("git", ["reset", "--hard"], cd: build_path)
  end

  def mix_deps_get(build_path) do
    bash("mix", ["deps.get", "--no-archives-check", "--only=prod"], cd: build_path)
  end

  def mix_compile(build_path) do
    bash("mix", ["local.rebar", "--force"], cd: build_path)
    bash("mix", ["compile", "--force"], cd: build_path)
    bash("mix", ["phoenix.digest"], cd: build_path)
  end

  def mix_release(build_path) do
    release_message = bash("mix", ["release", "--no-confirm-missing"], cd: build_path)
    Regex.named_captures(~r/(?<version>\d+\.\d+\.\d\S+)\s+is\s+ready/, release_message)
    |> Map.fetch!("version")
  end

  def git_sha(build_path) do
    System.cmd("git", ["rev-parse", "--short", "HEAD"], cd: build_path)
    |> elem(0) |> String.trim()
  end

  def make_deploy_dir(deploy_path) do
    File.mkdir_p(deploy_path)
  end

  def copy_release_to_deploy(build_path, deploy_path, version) do
    project     = Path.basename(build_path)
    deploy_path = Path.join(deploy_path, "#{project}.tar.gz")

    [build_path, "rel", project, "releases", version, "#{project}.tar.gz"]
    |> Path.join()
    |> File.cp(deploy_path)
  end

  def expand_release(project, deploy_path) do
    bash("tar", ["-xf", "#{project}.tar.gz"], cd: deploy_path)
  end

  def install_init_script(project_name, port) do
    file      = script_template(project_name: project_name, port: port)
    init_path = "/etc/init.d/#{project_name}"
    File.write(init_path, file)
    File.chmod(init_path, 0100)
    bash("update-rc.d", [project_name, "defaults"])
  end

  def start_service(project, port) do
    bash("sudo", ["service", project, "start"], env: [{"PORT", to_string(port)}])
  end

  def install_nginx_site(build_path, port) do
    project_name = build_path |> Path.basename()
    file         = nginx_template( domains: domains(build_path), port: port,)
    available    = "/etc/nginx/sites-available/#{project_name}"
    enabled      = "/etc/nginx/sites-enabled/#{project_name}"
    File.write(available, file)
    File.ln_s(available, enabled)
    bash("nginx", ["-s", "reload"])
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
