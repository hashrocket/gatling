defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  import Gatling.Bash
  import Gatling.Utilities

  def run([project]) do
    upgrade(project)
  end

  def upgrade(project) do
    build_dir    = build_dir(project)
    version      = version(project)
    upgrade_path = upgrade_path(project)
    release_path = built_release_path(project)

    bash("mix", ["deps.get"], cd: build_dir)
    bash("mix", ~w[compile --force], cd: build_dir)
    bash("mix", ~w[phoenix.digest -o public/static], cd: build_dir)
    bash("mix", ~w[release --no-confirm-missing], cd: build_dir)

    File.mkdir_p(upgrade_path)
    File.cp(release_path, upgrade_path)

    bash("service", ~w[#{project} upgrade #{version}], [])
  end

end
