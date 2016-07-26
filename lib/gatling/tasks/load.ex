defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task

  import Gatling.Bash, only: [bash: 3, log: 1]

  @build_path System.user_home

  def run([]) do
    project_name = Mix.Shell.IO.prompt("Please enter a project name:")
    load(project_name)
  end

  def run([project_name]) do
    load(project_name)
  end

  def load(project_name) do
    dir = dir(project_name) 
    if File.exists?(dir) do
      log(~s(-> #{dir} already exists))
    else
      File.mkdir_p!(dir)
      template_dir = File.join(Mix.Project.app_path, "git_template")
      bash("git", ["init", dir], env: [ {"GIT_TEMPLATE_DIR", template_dir} ])
    end
  end

  defp dir(project_name) do
    project = String.strip(project_name)
    @build_path |> Path.join(project)
  end

end
