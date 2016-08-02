defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task
  require EEx

  import Gatling.Bash, only: [bash: 3, log: 1]

  @moduledoc """
    Create a git repository for your mix project. The name of the project must match `:app` in your mix.exs
  """

  @shortdoc "Create a git repository or your mix project"

  def run([]) do
    project_name = Mix.Shell.IO.prompt("Please enter a project name:")
    load(project_name)
  end

  def run([project_name]) do
    load(project_name)
  end

  def load(project_name) do
    build_path =  Gatling.Utilities.build_path(project_name)
    if File.exists?(build_path) do
      log(~s(#{build_path} already exists))
    else
      File.mkdir_p!(build_path)
      bash("git", ["init", build_path], [])
      bash("git", ~w[config receive.denyCurrentBranch updateInstead], cd: build_path)
      install_post_receive_hook(build_path, project_name)
    end
  end

  def install_post_receive_hook(path, project_name) do
    file        = git_hook_template(project_name: project_name)
    script_path = [path, ".git", "hooks", "post-update"] |> Path.join()

    File.write(script_path, file)
    File.chmod(script_path, 775)
  end

  EEx.function_from_file( :def,
    :git_hook_template,
    __DIR__ |> Path.dirname |> Path.join("git_hook_template.sh.eex"),
    [:assigns]
  )

end
