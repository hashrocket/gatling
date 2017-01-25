defmodule Mix.Tasks.Gatling.Receive do
  use Mix.Task

  import Gatling.Bash

  @moduledoc """
  Run by git's `post-update` hook. Upgrades an existing app,
  otherwise does nothing until the app gets manually deployed.
  """

  @shortdoc "Do a hot upgrade on currently deployed project"

  @type project :: binary()
  @type gatling_env :: %Gatling.Env{}

  @spec run([project]) :: gatling_env
  def run([project]) do
    case bash("service", ~w[#{project} ping], into: "") do
      {"pong\n", 0} ->
        Mix.Tasks.Gatling.Upgrade.upgrade(project)

      _ ->
        Mix.Shell.IO.info("""
        The app #{project} is not deployed yet.
        Please invoke the initial deployment manually by running the following command:

        $ sudo --preserve-env mix gatling.deploy #{project}

        In case you already deployed the app, make sure it is running so that an upgrade can be performed.
        """)
    end
  end
end
