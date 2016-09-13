defmodule Gatling.Mixfile do
  use Mix.Project

  def version, do: "0.1.0"
  def project do
    [
      app: :gatling,
      version: version,
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "Gatling",
      source_url: "https://github.com/hashrocket/gatling",
      package: package,
      description: description,
      aliases: aliases,
      deps: deps,
      docs: [
        extras: [ "README.md" ]
      ],
    ]
  end

  defp description do
    "Enjoy heroku like deployments with Distillery and your own server"
  end

  defp package do
    [
      name: :gatling,
      licenses: ["Apache 2.0"],
      maintainers: ["Micah Cooper", "Hashrocket"],
      links: %{
        "GitHub" => "https://github.com/hashrocket/gatling",
      }
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [ {:ex_doc, ">= 0.0.0"} ]
  end

  defp aliases do
    [ build: [ &build_releases/1]]
  end

  defp build_releases(_) do
    Mix.Tasks.Compile.run([])
    Mix.Tasks.Archive.Build.run([])
    Mix.Tasks.Archive.Build.run(["--output=gatling.ez"])
    File.rename("gatling.ez", "./archives/gatling.ez")
    File.rename("gatling-#{version}.ez", "./archives/gatling-#{version}.ez")
  end

end
