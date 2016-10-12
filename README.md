# Gatling

[![Build Status](https://travis-ci.org/hashrocket/gatling.svg?branch=master)](https://travis-ci.org/hashrocket/gatling) [![Hex Version](https://img.shields.io/hexpm/v/gatling.svg)](https://hex.pm/packages/gatling)

Conveniently deploy a bunch of Phoenix apps

The main goal of Gatling is to make it very easy, cheap, and convenient to
deploy Phoenix apps.

Gatling is essentially a collection of mix tasks that (from a Git push)
automatically create an Distillery release and launches/upgrades it on your
server.

## NOTE:
As of Gatling v1.0.0, [Distillery](https://github.com/bitwalker/distillery), is
the assumed release building tool as opposed to Exrm.
To upgrade from a previous verison of Gatling, take the following steps:

SSH into your deployment server and run

Install at the latest version of gatling:

`mix archive.install https://github.com/hashrocket/gatling_archives/raw/master/gatling.ez`

In your project's `mix.exs`, remove the  `exrm` dependency and add `distillery`
in its stead

## Gatling, Distillery and Nginx
As you read through the instructions, keep in mind that both Distillery and
Nginx have tons of options you can configure outside of Gatling. Gatling's goal
is is to offer an out-of-the-box solution that keeps out of the way of your
custom deployment stategy. For example, Distillery requires a configuration
file in `./rel/config.exs` of your project. There is a
[lot](https://hexdocs.pm/distillery/configuration.html) you can do with this
but if you decide not to install this yourself, Gatling will generate a basic
one for you.

Please see the [Distillery](https://hexdocs.pm/distillery/getting-started.html)
docs to unlock the full power of your releases while Gatling simply triggers
them in a convenient way.

## Instructions

### Setting up the server
This has been tested on an Ubuntu 16.04 x64 server on Ec2 and Digital Ocean.

Install elixir, nginx, and the Gatling archive on your server

```bash
$ ssh server.address
```
Follow instructions
[here](http://elixir-lang.org/install.html#unix-and-unix-like) to install
elixir

```bash
$ sudo apt-get install nginx git
$ mix archive.install https://github.com/hashrocket/gatling_archives/raw/master/gatling.ez
```

If needed, install hex and rebar:

```
mix local.hex
mix local.rebar
```

###  Deploying your app

For a brand new project:

SSH into your server and run the following:

```bash
$ mix gatling.load {mix project name}
```
This only creates git repository on your server. Remember, when pushing to this
repository, it would be `remote_server_username@address.to_server:<project name>`
e.g. for a Digital Ocean box, you would push  to
`root@xx.xx.xx.xx:sample_project`

Ensure your elixir project can build a production release with
[Distillery](https://github.com/bitwalker/distillery)

Add a file to the root of your project named `domains` and  list  all  domains
that will point to this project. See an example
[here](https://github.com/hashrocket/gatling/tree/master/test/sample_project)

In your `config/prod.exs` make sure your `port` configuration uses an
environment variable called `PORT` (Gatling will set this for you
automatically):

 ```elixir
config :my_app, MyApp.Endpoint, [
  http: [port: {:system, "PORT"}],
  # root: ".", # add if using Phoenix
  # server: true, # add if using Phoenix
  # url: [host: "www.yourdomain.com"], # add if using Phoenix
]

config :phoenix, :serve_endpoints, true # uncomment if your using Phoenix
 ```

Setup your git remote and push to your server:

```elixir
$ git remote add production user_with_root_access@<address.to.server>:<project_name>
$ git push production master
```

SSH back into your server and ensure you have your `secret.exs` file(s)
installed if needed

Set your environment to `prod` by adding the following to `/etc/environment`

```bash
MIX_ENV=prod
```

For the initial deploy. Run `$ sudo mix gatling.deploy {project_name}` and Gatling
will do the following.

- Create a `distillery` release and put all the parts in the right place
- Find an open port, configure nginx to proxy to your app
- Create an `init.d` file so your app will boot if/when your server restarts

### Performing hot upgrades to your running application

Once your app is running do the following:

- Increase the version number of your application. See
  [here](https://github.com/hashrocket/gatling/blob/master/mix.example.exs) for
  an example to automatically increase the version number along with your
  commit.
- Commit your new changes
- `git push path.to.remote:project`

And that's it! You'll see the new version being deployed with no downtime!

##Callbacks

### Gatling.Tasks.Deploy

In your project root, create a file called `deploy.exs`. Define any of the
following functions to to wrap the Gatling deployment actions:

```elixir
defmodule SampleProject.DeployCallbacks do

  def before_mix_deps_get(env)
  def after_mix_deps_get(env)

  def before_mix_compile(env)
  def after_mix_compile(env)

  def before_mix_digest(env)
  def after_mix_digest(env)

  def before_mix_release_init(env)
  def after_mix_release_init(env)

  def before_mix_release(env)
  def after_mix_release(env)

  def before_make_deploy_dir(env)
  def after_make_deploy_dir(env)

  def before_copy_release_to_deploy(env)
  def after_copy_release_to_deploy(env)

  def before_expand_release(env)
  def after_expand_release(env)

  def before_install_init_script(env)
  def after_install_init_script(env)

  def before_mix_ecto_setup(env)
  def after_mix_ecto_setup(env)

  def before_start_service(env)
  def after_start_service(env)

  def before_configure_nginx(env)
  def after_configure_nginx(env)

end

```

__Note:__ the `env` is passed to every function. It is a READ only struct you
can use. Returning `env` from a callback function will have no effect on the
rest of the deployment process. [Here](/env.example.exs) is an example of the
`env` that is passed in.

### Gatling.Tasks.Upgrade

In your project root, create a file called `upgrade.exs`. Define any of the
following functions to to wrap the Gatling upgrade actions:

```elixir
defmodule SampleProject.UpgradeCallbacks do

  def before_mix_deps_get(env)
  def after_mix_deps_get(env)

  def before_mix_compile(env)
  def after_mix_compile(env)

  def before_mix_digest(env)
  def after_mix_digest(env)

  def before_mix_release_init(env)
  def after_mix_release_init(env)

  def before_mix_release(env)
  def after_mix_release(env)

  def before_make_upgrade_dir(env)
  def after_make_upgrade_dir(env)

  def before_copy_release_to_upgrade(env)
  def after_copy_release_to_upgrade(env)

  def before_upgrade_service(env)
  def after_upgrade_service(env)

end
```

__Note:__ the `env` is passed to every function. It is a READ only struct you
can use. Returning `env` from a callback function will have no effect on the
rest of the upgrade process.
[Here](https://github.com/hashrocket/gatling/blob/master/env.example.exs) is an
example of the `env` that is passed in.

#### System Commands in your callbacks.

While implementing your callback funtions. If you are going to use
`System.cmd/3`, use `bash/3` instead to get a prettier and more transparent
output

#### Example
Say I want to install wget before my dependencies are installed in the `deploy`
task.  I would create a file in my project called `./deploy.exs` with the
following:

```elixir
defmodule SampleProject.DeployCallbacks do

  def before_mix_deps_get(_env) do
    bash("sudo", ~w[apt-get install wget]
  end

end
```
This function will be called right before `mix deps get`

Say I want the server to run npm install + brunch build and recompile assets

```elixir
defmodule SampleProject.DeployCallbacks do

  def after_mix_digest(env) do
    bash("mkdir", ~w[-p priv/static], cd: env.build_dir) # optional: release may complain about this directory not existing
    bash("npm", ~w[install], cd: env.build_dir)
    bash("brunch", ~w[build --production], cd: env.build_dir)
    bash("mix", ~w[phoenix.digest -o public/static], cd: env.build_dir)
    env
  end

end
```
This function will be called right after `mix digest`

## Development

```
$ git clone https://github.com/hashrocket/gatling.git
$ cd gatling
$ mix deps.get
#Clone the archives repo
$ git clone https://github.com/hashrocket/gatling_archives.git
```

## Releases

To create a new release, take the following steps:

1. Bump your verson number in `mix.exs`
2. `git add . && git commit -m 'bump to v<version>'`
3. `$ MIX_ENV=prod mix do compile, build`
4. `$ cd gatling_archives`
5. `$ git add .`
6. `$ git commit -m "release v<version>"`
7. `$ git push origin master`
8. `$ cd ../ && git tag v<version>`
9. `$ git push origin <tag>`

## About

[![Hashrocket
logo](https://hashrocket.com/hashrocket_logo.svg)](https://hashrocket.com)

Gatling is supported by the team at [Hashrocket, a multidisciplinary design and
development consultancy](https://hashrocket.com). If you'd like to [work with
us](https://hashrocket.com/contact-us/hire-us) or [join our
team](https://hashrocket.com/contact-us/jobs), don't hesitate to get in touch.
