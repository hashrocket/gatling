defmodule Mix.Tasks.Gatling.Deploy do
  use Mix.Task

  import Gatling.Bash
  import Gatling.Utilities

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
    deploy_path  = deploy_path(project)
    deploy_dir   = deploy_dir(project)
    build_dir    = build_dir(project)
    port         = available_port
    release_path = built_release_path(project)

    bash("mix", ~w[deps.get],                        cd: build_dir)
    bash("mix", ~w[compile --force],                 cd: build_dir)
    bash("mix", ~w[phoenix.digest -o public/static], cd: build_dir)
    bash("mix", ~w[release --no-confirm-missing],    cd: build_dir)

    File.mkdir_p!(deploy_dir)
    File.cp!(release_path, deploy_path)

    bash("tar", ~w[-xf #{project}.tar.gz], cd: deploy_dir )

    install_nginx_site(project, port)
    install_init_script(project, port)
    bash("service", ~w[#{project} start], env: [{"PORT", to_string(port)}])
  end

  def install_init_script(project, port) do
    file      = script_template(project_name: project, port: port)
    init_path = etc_path(project)
    File.write!(init_path, file)
    File.chmod!(init_path, 0o777)
    bash("update-rc.d", ~w[#{project} defaults])
  end

  def install_nginx_site(project, port) do
    if domains = domains(project) do
      file         = nginx_template(domains: domains, port: port,)
      available    = nginx_available_path(project)
      enabled      = nginx_enabled_path(project)
      File.write!(available, file)

      unless File.exists?(enabled) do
        File.ln_s(available, enabled)
      end

      bash("nginx", ~w[-s reload])
    else
      log("""

      No 'domains' file detected. If you want to auto-configure nginx,
      Add a file called 'domains' to the root of your project. See
      "https://github.com/hashrocket/gatling/tree/master/test/sample_project"
      for an example.
      """)
    end
  end

end
