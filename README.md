# Gatling

Conveniently deploy a bunch of elixir plug apps

The main goal of Gatling is to make it very easy, cheap, and convenient 
to deploy Phoenix apps.

## Instructions

### Setting up the server

Install the app on your server

```
mix archive.install https://github.com/hashrocket/gatling/raw/master/releases/gatling-0.0.2.ez
```

### Deploying your app

For a brand new project:

- SSH into your server
- `$mix gatling.load {mix project name}`
- Ensure your elixir project can build a release with Exrm
- Add a file to the root of your project named `domains` and
add a list of all the domains you want this point to your project.
-  In your `config/prod.exs` set `cache_static_manifest` to `"public/static/manifest.json"`
- `git remote add production git@<address.to.server>:<project_name>.git`
- `git push production master`

Thats it!!! You are live.
