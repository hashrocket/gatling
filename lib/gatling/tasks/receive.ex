defmodule Mix.Tasks.Gatling.Receive do
  use Mix.Task

  @moduledoc """
    Run by git's post-update hook. Determe whether to deploy the app, or update an existing one. 
  """

  @shortdoc """
    Run by git's post-update hook. Deploy the app, or update the existing one. 
  """

  def run([path]) do
    project = Path.basename(path)
    deploy_path = Path.join([System.user_home, "deployments", project])

    if File.exists?(deploy_path) do
      Mix.Tasks.Gatling.Upgrade.upgrade(path)
    else
      Mix.Tasks.Gatling.Deploy.deploy(path)
    end

  end
end
