defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task

  import Gatling.Bash, only: [bash: 2, bash: 3, log: 1]

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
      bash("git", ["init", dir])
      bash("git", ["config", "receive.denyCurrentBranch", "updateInstead"], cd: dir)
      post_receive_hook(dir)
    end
  end

  def post_receive_hook(path) do
    script = """
    #!/bin/sh

    unset GIT_DIR
    exec mix gatling.receive #{path}
    """
    script_path = [path, ".git", "hooks", "post-update"] |> Path.join()
    File.write(script_path, script)
    File.chmod(script_path, 00101)
  end

  defp dir(project_name) do
    project = String.strip(project_name)
    System.user_home |> Path.join(project)
  end

end
