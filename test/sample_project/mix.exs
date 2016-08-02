defmodule SampleProject.Mixfile do
  use Mix.Project

  def project do
    [app: :sample_project,
     version: "0.0.0",
     aliases: aliases,
   ]
  end

  def application do
    [applications: []]
  end

  defp aliases do
    [
      release: &release/1,
      compile: fn(_) -> IO.puts "Compiled" end,
      "deps.get": fn(_)-> IO.puts "Downloaded Dependencies" end,
      "phoenix.digest": fn(_)-> IO.puts "Assets have been compiled" end,
    ]
  end

  defp release(_) do
    path = "rel/sample_project/releases/0.0.0"
    File.mkdir_p(path)
    File.write("rel/sample_project/releases/0.0.0/sample_project.txt", "hello")
    System.cmd("tar", ~w[cf sample_project.tar.gz sample_project.txt], cd: path)
    Mix.Shell.IO.info "version 0.0.0 is ready"
  end

end
