defmodule Gatling.Utilities do

  def nginx_path, do: Application.get_env(:gatling, :nginx_path)
  def etc_path,   do: Application.get_env(:gatling, :etc_path)

  def build_path(project_name) do
    project   = String.strip(project_name)
    build_dir = Application.get_env(:gatling, :build_path).()
    Path.join(build_dir, project)
  end

  def deploy_dir(project) do
    Path.join([
      Application.get_env(:gatling, :deploy_path).(),
      project,
    ])
  end

  def upgrade_dir(project, version) do
    Path.join([
      deploy_dir(project),
      "releases",
      version,
    ])
  end

  def available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

end
