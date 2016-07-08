defmodule Mix.Tasks.Gatling.Deploy do
  @module """
  - Copy most recent deploy into deploy directory found at %{System.user_home}/deployed/<project_name>
  - If this is an initial deploy:
  - create a init script for the app
  - add app with the domains to nginx configuration
  - start the service
  - If this is an upgrade
  - perform hot upgrade to the running application
  """

  @build_location System.user_home
  @deploy_location "/app"

  def run([project]) do
    unless File.exists?(@deploy_location), do: File.mk_dir(@deploy_location)
    GatlingInitScript.install(project)
  end

  defp copy_release_to_deploy(project) do

  end

  defp latest_release(project) do
    mix_path           = Path.join([@build_location, project,  "mix.exs"])
    [{application, _}] = Code.load_file(mix_path)
    version            = application.project[:version]

    Path.join([@build_location, project, "rel", project, "releases", version ])
  end

end
