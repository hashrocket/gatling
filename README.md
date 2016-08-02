# Gatling

Conveniently deploy a bunch of elixir phoenix apps

The main goal of Gatling is to make it very easy, cheap, and convenient to deploy Phoenix apps.

## Instructions

### Setting up the server
This has been tested on an Ubuntu 16.04 x64 server on Ec2 and Digital Ocean.

Install elixir, nginx, and the Gatling archive on your server

```bash
$ ssh server.adderss
```
Follow instructions [here](http://elixir-lang.org/install.html#unix-and-unix-like) to install elixir
```bash
$ sudo apt-get install nginx
$ mix archive.install https://github.com/hashrocket/gatling/raw/master/releases/gatling-0.0.3.ez
```

###  Deploying your app

For a brand new project:

SSH into your server and run the following:

```bash
$ mix gatling.load {mix project name}
```
Ensure your elixir project can build a release with [Exrm](https://github.com/bitwalker/exrm)

Add a file to the root of your project named `domains` and  list  all  domains that will point to this project

In your `config/prod.exs` change `cache_static_manifest` to and make sure your `port` configuration uses an environment variable called `PORT`(Gatling will set this for you automatically):

 ```elixir
config :my_app, MyApp.Endpoint, [
  cache_static_manifest: "public/static/manifest.json",
  http: [port: {:system, "PORT"}],
]
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

And that's it! You'll see the new version being deployed.
