defmodule Mix.Tasks.Gatling.Receive do
  use Mix.Task

  @moduledoc """
  Run by git's post-update hook. Determe whether to deploy the app, or update an existing one.
  """

  @shortdoc "Deploy project or update the existing one"

  def run([project]) do
    deploy_dir = Gatling.Utilities.deploy_dir(project)

    if File.exists?(deploy_dir) do
      Mix.Tasks.Gatling.Upgrade.upgrade(project)
    else
      Mix.Tasks.Gatling.Deploy.deploy(project)
    end

  end
end
