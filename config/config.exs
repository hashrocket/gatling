use Mix.Config

if Mix.env == :test do

  config :gatling, [

  build_dir: fn ->
    Path.join(~w[#{System.cwd} test root home ubuntu])
  end,

  deploy_dir: fn ->
    Path.join(~w[#{System.cwd} test root home ubuntu deployments])
  end,

  nginx_dir: Path.join(
    ~w[#{System.cwd} test root etc nginx]
  ),

  etc_dir: Path.join(
    ~w[#{System.cwd} test root etc init.d]
  ),

]
end
