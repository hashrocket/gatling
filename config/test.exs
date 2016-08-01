use Mix.Config

config :gatling, [
  build_path: fn ->
    Path.join(~w[#{System.cwd} test root home ubuntu])
  end,

  deploy_path: fn ->
    Path.join(~w[#{System.cwd} test root home ubuntu deployments])
  end,

  nginx_path: Path.join(
    ~w[#{System.cwd} test root etc nginx]
  ),

  etc_path: Path.join(
    ~w[#{System.cwd} test root etc init.d]
  ),

]
