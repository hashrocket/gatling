defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  alias Mix.Tasks.Gatling.Deploy
  import Gatling.Bash, only: [bash: 3]

  def run([project]) do
    upgrade(project)
  end

  def upgrade(project) do
    deploy_path  = Gatling.Utilities.deploy_dir(project)
    build_path   = Gatling.Utilities.build_path(project)

    Deploy.mix_deps_get(build_path)
    Deploy.mix_compile(build_path)

    version     = Deploy.mix_release(build_path)
    upgrade_dir = Gatling.Utilities.upgrade_dir(project, version)

    Deploy.make_deploy_dir(upgrade_dir)
    Deploy.copy_release_to_deploy(build_path, upgrade_dir, version)

    upgrade_service(project, version)
  end

  def upgrade_service(project, version) do
    bash("service", ~w[#{project} upgrade #{version}], [])
  end

end
