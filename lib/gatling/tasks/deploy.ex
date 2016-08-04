defmodule Mix.Tasks.Gatling.Deploy do
  use Mix.Task

  import Gatling.Bash, only: [bash: 2, bash: 3]

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
    deploy_path  = Gatling.Utilities.deploy_path(project)
    build_dir    = Gatling.Utilities.build_dir(project)
    port         = Gatling.Utilities.available_port
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
  end

  def expand_release(deploy_path) do
    bash("tar", ~w[-xf #{deploy_path}])
  end

  def install_init_script(project, port) do
    file      = Gatling.Utilities.script_template(project_name: project, port: port)
    init_path = Gatling.Utilities.etc_path(project)
    File.write(init_path, file)
    File.chmod(init_path, 777)
    bash("update-rc.d", ~w[#{project} defaults])
  end

  def start_service(project, port) do
    bash("service", ~w[#{project} start], env: [{"PORT", to_string(port)}])
  end

  def install_nginx_site(project, port) do
    if domains = Gatling.Utilities.domains(project) do
      file         = Gatling.Utilities.nginx_template(domains: domains, port: port,)
      available    = Gatling.Utilities.nginx_available_path(project)
      enabled      = Gatling.Utilities.nginx_enabled_path(project)
      File.write(available, file)

      unless File.exists?(enabled) do
        File.ln_s(available, enabled)
      end

      bash("nginx", ~w[-s reload])
    else
      Gatling.Bash.log("""

      No 'domains' file detected. If you want to auto-configure nginx,
      Add a file called 'domains' to the root of your project. See
      "https://github.com/hashrocket/gatling/tree/master/test/sample_project"
      for an example.
      """)
    end
  end

end
