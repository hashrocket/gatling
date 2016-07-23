defmodule Mix.Tasks.Gatling.Upgrade do
  use Mix.Task

  import Gatling.Bash, only: [bash: 3, bash: 2]

  def run([]) do
    build_path = Mix.Shell.IO.prompt("Please enter the path to your project:")
                  |> String.trim()
    upgrade(build_path)
  end

  def run([build_path]) do
    upgrade(build_path)
  end

  def upgrade(build_path) do
    project       = Path.basename(build_path)
    deploy_path   = Path.join([System.user_home, "deployments", project])
    releases_path = Path.join([build_path, "rel", project, "releases"])

    git_reset_hard(build_path)
    mix_deps_get(build_path)
    mix_compile(build_path)
    mix_release(build_path)
    copy_release_to_deploy(build_path, deploy_path)
    upgrade_service(project)
  end

  def upgrade_service(project) do
    System.cmd("sudo", ["service", project, "upgrade", version])
  end

  def git_reset_hard(build_path) do
    bash("git", ["reset", "--hard"], cd: build_path)
  end

  def mix_deps_get(build_path) do
    bash("mix", ["deps.get"], cd: build_path)
  end

  def mix_compile(build_path) do
    bash("mix", ["compile"], cd: build_path)
  end

  def mix_release(build_path) do
    bash("mix", ["release", "--no-confirm-missing"], cd: build_path)
  end

  def git_sha(build_path) do
    System.cmd("git", ["rev-parse", "--short", "HEAD"], cd: build_path)
    |> elem(0) |> String.trim()
  end

  def copy_release_to_deploy(build_path, deploy_path) do
    release_from = release_from(build_path)
    File.cp(release_from, deploy_path)
  end

  def release_from(build_path) do
    project = Path.basename(build_path)
    version = version(build_path)

    [build_path, "rel", project, "releases", version, "#{project}.tar.gz"]
    |> Path.join()
  end

  def version(build_path, project\\nil) do
    project = Path.basename(build_path)
    sha     = git_sha(build_path)
    Path.join([build_path, "rel", project, "releases"])
    |> File.ls!()
    |> Enum.find(fn(path) -> Regex.match?(~r/#{sha}$/, path) end)
  end


end
