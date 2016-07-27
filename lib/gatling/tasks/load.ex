defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task

  import Gatling.Bash, only: [bash: 2, bash: 3, log: 1]

  @moduledoc """
    Create a git repository for your mix project. The name of the project must match `:app` in your mix.exs
  """

  @shortdoc """
    Create a git repository or your mix project
  """

  def run([]) do
    project_name = Mix.Shell.IO.prompt("Please enter a project name:")
    load(project_name)
  end

  def run([project_name]) do
    load(project_name)
  end

  defp load(project_name) do
    build_path =  Gatling.Utilities.build_path(project_name)
    if File.exists?(build_path) do
      log(~s(#{build_path} already exists))
    else
      File.mkdir_p!(build_path)
      bash("git", ["init", build_path])
      bash("git", ["config", "receive.denyCurrentBranch", "updateInstead"], cd: build_path)
      post_receive_hook(build_path)
    end
  end

  defp post_receive_hook(path) do
    script = """
    #!/bin/sh

    unset GIT_DIR
    exec sudo mix gatling.receive #{path}
    """
    script_path = [path, ".git", "hooks", "post-update"] |> Path.join()
    File.write(script_path, script)
    File.chmod(script_path, 00101)
  end

end
