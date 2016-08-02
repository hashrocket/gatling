defmodule Mix.Tasks.Gatling.Receive do
  use Mix.Task

  @moduledoc """
  Run by git's post-update hook. Determe whether to deploy the app, or update an existing one.
  """

  @shortdoc "Do a hot upgrade on currently deploye project"

  def run([project]) do
    if File.exists? Gatling.Utilities.deploy_dir(project) do
      Mix.Tasks.Gatling.Upgrade.upgrade(project)
    end
  end
end
