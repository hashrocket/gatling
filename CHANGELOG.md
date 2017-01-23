# Gatling Changelog

## v1.1.0

Gatling v1.1.0 catches up with a changed default build directory in Distillery.
In Distillery up to v0.11, the default path for release artifacts has been `rel/<release_name>`.
v0.11 and later versions place the release artifacts in `_build/$MIX_ENV/rel/<release_name>`, which is Gatlings new default.

For details see
[#35](https://github.com/hashrocket/gatling/pull/35),
[#29](https://github.com/hashrocket/gatling/issues/29), and
[#4](https://github.com/hashrocket/gatling/issues/4#issuecomment-257626656)

## v1.0.0

As of Gatling v1.0.0, [Distillery](https://github.com/bitwalker/distillery), is
the assumed release building tool as opposed to Exrm.
To upgrade from a previous version of Gatling, take the following steps:

SSH into your deployment server and install the latest version of Gatling:

```
$ mix archive.install https://github.com/hashrocket/gatling_archives/raw/master/gatling.ez
```

In your project's `mix.exs`, remove the `exrm` dependency and add `distillery`
in its stead.
