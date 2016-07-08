defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task

  import Mix.Shell.IO, only: [prompt: 1, info: 1]

  @working_dir System.user_home

  def run([]) do
    project_name = prompt("Please enter a project name:")
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
      System.cmd("git", ["init", dir])
      info ~s(-> #{dir} created)
    end
  end

  defp dir(project_name) do
    project = String.strip(project_name)
    @working_dir |> Path.join(project)
  end

end
