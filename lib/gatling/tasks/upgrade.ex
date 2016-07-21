defmodule Mix.Tasks.Gatling.Upgrade do
  import Logger, only: [info: 1]

  def run([build_path, deploy_path]) do
    project = build_path |> Path.basename()
    releases_path = Path.join([build_path, "rel", project, "releases"])
    sha = System.cmd("git", ["rev-parse", "--short", "HEAD"], cd: build_path) |> elem(0)  |> String.trim()

    info System.cmd("git", ["reset", "--hard"]) |> elem(0)
    info System.cmd("mix", ["deps.get"], cd: build_path) |> elem(0)
    info System.cmd("mix", ["compile"], cd: build_path) |> elem(0)
    info System.cmd("mix", ["release"], cd: build_path) |> elem(0)

    version  = File.ls!(releases_path) 
             |> Enum.find(fn(path) -> Regex.match?(~r/#{sha}$/, path) end)

    deploy_to = Path.join([deploy_path, "releases", version])
    release_from = Path.join([build_path, "rel", project, "releases", version, "#{project}.tar.gz" ])

    File.mkdir(deploy_to); info "Created #{deploy_to}"
    File.cp(release_from, deploy_to); info "Copied #{release_from} -> #{deploy_to}"

    info System.cmd("sudo", ["service", project, "upgrade", version]) |> elem(0)
  end
end
