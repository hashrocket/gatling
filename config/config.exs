use Mix.Config

config :gatling, [
  build_path: fn -> System.user_home end,
  deploy_path: fn -> Path.join([System.user_home, "deployments"]) end,
  nginx_path: "/etc/nginx",
  service_path: "/etc/init.d",
]

if Mix.env == :test do
  import_config "test.exs"
end
