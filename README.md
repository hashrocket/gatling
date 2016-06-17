# Gatling

Conveniently deploy a bunch of elixir plug apps

The main goal of Gatling is to make it very easy, cheap, and convenient 
to deploy Phoenix apps.

## Instructions

### Setting up the server

- Setup an UbuntuCore server anywhere [instructions](https://feliciano.tech/blog/running-ubuntu-snappy-core-on-linode/)
- Install this gatling Snap

### Deploying your app

For a brand new project:

- SSH into your server
- `$mix gatling.load <repo_name>

- Ensure your elixir project can build a release with Exrm
- Add a file to the root of your project named `gatling.domains` and
add a list of all the domains you want this point to your project.
- `git remote add production git@<address.to.server>:<project_name>.git`
- `git push production master`

Thats it!!! You are live.
