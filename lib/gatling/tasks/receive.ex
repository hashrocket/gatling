defmodule Mix.Tasks.Gatling.Receive do
  use Mix.Task

  import Gatling.Utilities

  @moduledoc """
  Run by git's `post-update` hook. Upgrades an existing app,
  otherwise does nothing until the app gets manually deployed.
  """

  @shortdoc "Do a hot upgrade on currently deployed project"

  @type project :: binary()
  @type gatling_env :: %Gatling.Env{}

  @spec run([project]) :: gatling_env
  def run([project]) do
    if File.exists? deploy_path(project) do
      Mix.Tasks.Gatling.Upgrade.upgrade(project)
    end
  end
end
