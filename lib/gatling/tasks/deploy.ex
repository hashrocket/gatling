defmodule Mix.Tasks.Gatling.Deploy do
  use Mix.Task

  import Gatling.Bash, only: [bash: 3, log: 1]

  @moduledoc """
  - Create a release of git HEAD using Exrm
  - Create a init script for the app so it will reboot on a server reboot
  - Configure Nginx go serve it
  - Start the app
  """

  @shortdoc "Create an exrm release of the given project and deploy it"

  def run([project_name]) do
    deploy(project_name)
  end

  defp deploy(project) do
    deploy_dir   = Gatling.Utilities.deploy_dir(project)
    deploy_path  = Gatling.Utilities.deploy_path(project)
    build_dir   = Gatling.Utilities.build_dir(project)
    port         = Gatling.Utilities.available_port
    version      = Gatling.Utilities.version(project)
    release_path = Gatling.Utilities.built_release_path(project)

    mix_deps_get(build_dir)
    mix_compile(build_dir)
    mix_release(build_dir)
    make_deploy_dir(deploy_path)
    copy_release_to_deploy(release_path, deploy_path)
    expand_release(deploy_path)
    install_nginx_site(project, port)
    install_init_script(project, port)
    start_service(project, port)
  end

  def mix_deps_get(build_dir) do
    bash("mix", ["deps.get"], cd: build_dir)
  end

  def mix_compile(build_dir) do
    bash("mix", ~w[compile --force], cd: build_dir)
    bash("mix", ~w[phoenix.digest -o public/static], cd: build_dir)
  end

  def mix_release(build_dir) do
    bash("mix", ~w[release --no-confirm-missing], cd: build_dir)
  end

  def make_deploy_dir(deploy_path) do
    File.mkdir_p(deploy_path)
  end

  def copy_release_to_deploy(release_path, deploy_path) do
    File.cp(release_path, deploy_path)
    log("Release copied to #{deploy_path}")
  end

  def expand_release(deploy_path) do
    bash("tar", ~w[-xf #{deploy_path}], message: "Extracting #{deploy_path}")
  end

  def install_init_script(project_name, port) do
    file      = Gatling.Utilities.script_template(project_name: project_name, port: port)
    init_path = Gatling.Utilities.etc_path(project_name)
    File.write(init_path, file)
    File.chmod(init_path, 0100)
    bash("update-rc.d", ~w[#{ project_name } defaults], [])
    log("Added service #{project_name} to #{Gatling.Utilities.etc_dir}")
  end

  def start_service(project, port) do
    bash("service", ~w[#{project} start], env: [{"PORT", to_string(port)}])
    log("Started service #{project}")
  end

  def install_nginx_site(project, port) do
    if domains = Gatling.Utilities.domains(project) do
      file         = Gatling.Utilities.nginx_template(domains: domains, port: port,)
      available    = Path.join([Gatling.Utilities.nginx_dir, "sites-available", project])
      enabled      = Path.join([Gatling.Utilities.nginx_dir, "sites-enabled", project])
      File.write(available, file)
      File.ln_s(available, enabled)
      bash("nginx", ~w[-s reload], message: "Configuring nginx")
    else
      ""
    end
  end

end
