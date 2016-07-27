use Mix.Config

config :gatling, [

  build_path: fn ->
    Path.join([System.cwd, "test", "root", "home", "ubuntu"])
  end,

  deploy_path: fn ->
    Path.join([System.cwd, "test", "root", "home", "ubuntu", "deployments"])
  end,

  nginx_path: Path.join(
    [System.cwd, "test", "root", "etc", "nginx"]
  ),

  etc_path: Path.join(
    [System.cwd, "test", "root", "etc", "init.d"]
  ),

]

