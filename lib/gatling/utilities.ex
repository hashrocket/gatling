defmodule Gatling.Utilities do

  def build_path(project_name) do
    project   = String.strip(project_name)
    build_dir = Application.get_env(:gatling, :build_path).()
    Path.join(build_dir, project)
  end

  def deploy_dir(project) do
    [
      Application.get_env(:gatling, :deploy_path).(),
      project,
    ] |> Path.join()
  end

  def nginx_path, do:  Application.get_env(:gatling, :deploy_path)
  def etc_path, do:  Application.get_env(:gatling, :deploy_path)

  def available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

end
