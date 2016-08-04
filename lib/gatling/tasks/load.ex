defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task

  import Gatling.Bash, only: [bash: 3, log: 1]

  @moduledoc """
    Create a git repository for your mix project. The name of the project must match `:app` in your mix.exs
  """

  @shortdoc "Create a git repository or your mix project"

  def run([]) do
    project = Mix.Shell.IO.prompt("Please enter a project name:")
    load(project)
  end

  def run([project]) do
    load(project)
  end

  def load(project) do
    build_dir =  Gatling.Utilities.build_dir(project)
    if File.exists?(build_dir) do
      log(~s(#{build_dir} already exists))
    else
      File.mkdir_p!(build_dir)
      bash("git", ["init", build_dir], [])
      bash("git", ~w[config receive.denyCurrentBranch updateInstead], cd: build_dir)
      install_post_receive_hook(project)
    end
  end

  def install_post_receive_hook(project) do
    file = Gatling.Utilities.git_hook_template(project_name: project)
    path = Gatling.Utilities.git_hook_path(project)

    File.write(path, file)
    File.chmod(path, 777)
  end

end
