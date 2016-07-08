defmodule Gatling.InitScript do
  require EEx

  EEx.function_from_file( :def,
    :script_template,
    Path.join([__DIR__, "init_script_template.sh.eex"]),
    [:assigns]
  )

  def install(project_name) do
    file = script_template(port: available_port, project_name: project_name)
    File.write("~/#{project_name}.sh", file)
  end

  defp available_port do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_number} = :inet.port(port)
    Port.close port
    port_number
  end

end
