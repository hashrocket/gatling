defmodule Mix.Tasks.Gatling.Load do
  use Mix.Task

  import Gatling.Bash
  import Gatling.Utilities

  @moduledoc """
    This is the first mix task to run when creating a new Gatling project.

    __IMPORTANT_NOTE__: The `<project_name>` must match `:app` in your mix.exs

    `mix gatling.load <project_name>` will perform:

    - Create a git repository for your mix project
    - Create a deployment directory for your mix project at `~/deployments/<project_name>`
  """

  @shortdoc "Load a new Gatling project to deploy to"

  @type project :: binary()

  @spec run([project]) :: nil
  def run([]) do
    project = Mix.Shell.IO.prompt("Please enter a project name:")
    load(project)
  end

  def run([project]) do
    load(project)
  end

  @spec load([project]) :: nil
  @doc """
  Create an empty git repository of the given project

  The repository contains a `post-update` hook that triggers the hot upgrade from future git pushes
  """
  def load(project) do
    build_dir = build_dir(project)

    if File.exists?(build_dir) do
      log(~s(#{build_dir} already exists))
    else
      File.mkdir_p!(build_dir)
      log("Created #{build_dir}")
      bash("git", ["init", build_dir], [])
      bash("git", ~w[config receive.denyCurrentBranch updateInstead], cd: build_dir)
      install_post_receive_hook(project)
    end

    deploy_dir = deploy_dir(project)

    unless File.exists?(deploy_dir) do
      File.mkdir_p!(deploy_dir)
      log("Created #{deploy_dir}")
    end

    nil
  end

  defp install_post_receive_hook(project) do
    file = git_hook_template(project: project)
    path = git_hook_path(project)

    File.write!(path, file)
    File.chmod!(path, 0o777)
  end

end
