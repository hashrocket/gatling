defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task

  import Gatling.Bash, only: [bash: 3, bash: 2]

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
      info ~s(-> #{dir} already exists)
    else
      File.mkdir_p!(dir)
      bash("git", ["init", dir])
    end
  end

  defp dir(project_name) do
    project = String.strip(project_name)
    @build_path |> Path.join(project)
  end

end
