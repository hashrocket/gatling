defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  alias Mix.Tasks.Gatling.Deploy
  import Gatling.Bash, only: [bash: 2, log: 1]

  def run([]) do
    build_path = Mix.Shell.IO.prompt("Please enter the path to your project:")
                  |> String.trim()
    upgrade(build_path)
  end

  def run([build_path]) do
    upgrade(build_path)
  end

  def upgrade(build_path) do

    Deploy.mix_deps_get(build_path)
    Deploy.mix_compile(build_path)

    project   = Path.basename(build_path)
    version   = Deploy.mix_release(build_path)
    deploy_to = Path.join([System.user_home, "deployments", project, "releases", version])

    Deploy.make_deploy_dir(deploy_to)
    Deploy.copy_release_to_deploy(build_path, deploy_to, version)

    upgrade_service(project, version)
  end

  def upgrade_service(project, version) do
    bash("sudo", ["service", project, "upgrade", version])
  end

end
