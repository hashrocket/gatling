defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  alias Mix.Tasks.Gatling.Deploy
  import Gatling.Bash, only: [bash: 3]

  def run([project]) do
    upgrade(project)
  end

  def upgrade(project) do
    build_dir    = Gatling.Utilities.build_dir(project)
    version      = Gatling.Utilities.version(project)
    upgrade_dir  = Gatling.Utilities.upgrade_dir(project)
    upgrade_path = Gatling.Utilities.upgrade_path(project)
    release_path = Gatling.Utilities.built_release_path(project)

    Deploy.mix_deps_get(build_dir)
    Deploy.mix_compile(build_dir)
    Deploy.mix_release(build_dir)
    Deploy.make_deploy_dir(upgrade_dir)
    Deploy.copy_release_to_deploy(release_path, upgrade_path)

    upgrade_service(project, version)
  end

  def upgrade_service(project, version) do
    bash("service", ~w[#{project} upgrade #{version}], [])
  end

end
