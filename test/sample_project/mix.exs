defmodule SampleProject.Mixfile do
  use Mix.Project

  def project do
    [app: :sample_project,
     version: version(),
     aliases: aliases(),
   ]
  end

  def application do
    [applications: []]
  end

  defp aliases do
    [
      "release.init": &release_init/1,
      release: &release/1,
      compile:          fn(_)-> IO.puts "Compiled" end,
      "deps.get":       fn(_)-> IO.puts "Downloaded Dependencies" end,
      "phoenix.digest": fn(_)-> IO.puts "Assets have been compiled" end,
    ]
  end

  defp release(_) do
    path = "_build/prod/rel/sample_project/releases/#{version()}"
    File.mkdir_p(path)
    File.write("#{path}/sample_project.txt", "hello")
    System.cmd("tar", ~w[cf sample_project.tar.gz sample_project.txt], cd: path)
    Mix.Shell.IO.info "version #{version()} is ready"
  end

  defp release_init(_) do
    File.mkdir_p("rel")
    File.write("rel/config.exs", "hello")
  end

  defp version do
   "0.0.1470406670"
  end

end
