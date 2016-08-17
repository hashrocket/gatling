# Gatling

Conveniently deploy a bunch of Phoenix apps

The main goal of Gatling is to make it very easy, cheap, and convenient to deploy Phoenix apps.

Gatling is essentially a collection of mix tasks that (from a Git push) automatically create an Exrm release and launches/upgrades it on your server.

## Instructions

### Setting up the server
This has been tested on an Ubuntu 16.04 x64 server on Ec2 and Digital Ocean.

Install elixir, nginx, and the Gatling archive on your server

```bash
$ ssh server.address
```
Follow instructions [here](http://elixir-lang.org/install.html#unix-and-unix-like) to install elixir
```bash
$ sudo apt-get install nginx
$ mix archive.install https://github.com/hashrocket/gatling/raw/master/releases/gatling-0.1.0.ez
```

###  Deploying your app

For a brand new project:

SSH into your server and run the following:

```bash
$ mix gatling.load {mix project name}
```
Ensure your elixir project can build a release with [Exrm](https://github.com/bitwalker/exrm)

Add a file to the root of your project named `domains` and  list  all  domains that will point to this project. See an example [here](https://github.com/hashrocket/gatling/tree/master/test/sample_project)

In your `config/prod.exs` change `cache_static_manifest` to and make sure your `port` configuration uses an environment variable called `PORT`(Gatling will set this for you automatically):

 ```elixir
config :my_app, MyApp.Endpoint, [
  cache_static_manifest: "public/static/manifest.json",
  http: [port: {:system, "PORT"}],
]
 ```

Add the following to your `.gitignore`:
```config
/public/static
```

Setup your git remote and push to your server:

```elixir
$ git remote add production git@<address.to.server>:<project_name>.git`
$ git push production master
```
SSH back into your server, run your migrations, and ensure you have your `secret.exs` file(s) installed if needed
Set your environment to `prod` by adding the following to `/etc/environment`
```bash
MIX_ENV=prod
```

Now for the initial deploy. Run `$ mix gatling.deploy {project_name}` and Gatling will do the following.
- Create a `exrm` release and put all the parts in the right place
- Find an open port, configure nginx to proxy to your app
- Create an `init.d` file so your app will boot if/when your server restarts

### Performing hot upgrades to your running application

Once your app is running do the following:

- Increase the version number of your application. See [here](https://github.com/hashrocket/gatling/blob/master/mix.example.exs) for an example to automatically increase the version number along with your commit.
- Commit your new changes
- `git push path.to.remote:project`

And that's it! You'll see the new version being deployed with no downtime!.
Thats it!!! You are golden.

##Callbacks

### Gatling.Tasks.Deploy

In your project root, create a file called `deploy.ex`. Define any of the following functions to to wrap the Gatling deployment actions:

```elixir
defmodule Gatling.DeployCallbacks do
  
  def before_mix_deps_get(env)
  def after_mix_deps_get(env)

  def before_mix_compile(env)
  def after_mix_compile(env)

  def before_mix_digest(env)
  def after_mix_digest(env)

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

__Note:__ the `env` is passed to every function. It is a READ only map that use can use. Returning `env` from a callback function will have not effect on the rest of the deployment process. [Here](/env.example.exs) is an example of the `env` that is passed in.

### Development

```
$ git clone https://github.com/hashrocket/gatling
$ cd gatling
$ mix deps.get
```
