defmodule Mix.Tasks.Gatling.Upgrade do
  def run([build_path]) do
    project       = build_path |> Path.basename()
    deploy_path   = Path.join([System.user_home, "app", project])
    releases_path = Path.join([build_path, "rel", project, "releases"])

    sha = System.cmd("git", ["rev-parse", "--short", "HEAD"], cd: build_path)
          |> elem(0) |> String.trim()

    System.cmd("git", ["reset", "--hard"]) |> elem(0) |> IO.write()
    System.cmd("mix", ["deps.get"], cd: build_path) |> elem(0) |> IO.write()
    System.cmd("mix", ["compile"], cd: build_path)  |> elem(0) |> IO.write()
    System.cmd("mix", ["release"], cd: build_path)  |> elem(0) |> IO.write()

    version  = File.ls!(releases_path)
             |> Enum.find(fn(path) -> Regex.match?(~r/#{sha}$/, path) end)

    deploy_to = Path.join([deploy_path, "releases", version])
    release_from = Path.join([build_path, "rel", project, "releases", version, "#{project}.tar.gz"])

    File.mkdir(deploy_to)
    info "Created #{deploy_to}"

    File.mv(release_from, deploy_to)
    info "Copied #{release_from} -> #{deploy_to}"

    System.cmd("sudo", ["service", project, "upgrade", version])
    |> elem(0) |> IO.write()
  end
end
