# fairbanks-server

Fairbanks server is an Elixir application using [Phoenix](http://www.phoenixframework.org/) to deliver weather updates to mobile clients.

See [Fairbanks](https://github.com/bryfox/Fairbanks).


## Release & Deploy

### Build server setup

- set up ssh access for server user with publickey auth
    + generate client key
    + add key to server authorized_keys
    + In `/etc/ssh/sshd_config`, ensure `PubkeyAuthentication yes`
- install elixir (incl. erlang and Mix dependencies)
    + ensure build user has `mix` location in `$PATH`
- Remote copy the prod.secret.exs file to some location on the build server ([see docs](https://github.com/boldpoker/edeliver/wiki/Embed-Secrets---Credentials-into-the-Release))

### Deployment server setup

- Create postgres user & DB based on config file. Migrations can be run as below.
- Set required env vars:
    + `PORT`: for Cowboy
    + `FAIRBANKS_FEED_URL`: e.g., 'https://example.com/rss.xml'. Defaults to localhost (see Mocks server below)
    + `FAIRBANKS_USER_AGENT`: e.g., 'myapp/v1'

### Distillery & EDeliver

[EDeliver](https://github.com/boldpoker/edeliver) coordinates with distillery on a build server, and delivers products for running on one or more destination servers. EDeliver configuration lives in `.deliver/`.

```
# 1. Build on the build server
$ mix edeliver build release staging --verbose --branch=release

# 2. Deliver artifact to the staging/production server
$ mix edeliver deploy release to staging --verbose

# 3. Start server (if not already)
$ mix edeliver start staging

# 4. Ecto migrations
$ mix edeliver show migrations on staging
$ mix edeliver migrate staging

$ mix edeliver ping staging
```

`--verbose` is used here; `--debug` can be used for all output.

Distillery is the build tool. To build locally, work with distillery directly. Distillery configuration lives in `/rel`.

```
$ mix release.clean
$ MIX_ENV=prod mix release
```

### Note on the asset pipeline

Assets are compiled and digested automatically during development; for the build server, the following steps are handled in the delivery script's `pre_erlang_clean_compile` step.

```
# Build assets for production
$ ./node_modules/brunch/bin/brunch b -p
# Digest assets (e.g. for cache busting)
$ MIX_ENV=prod mix phoenix.digest
```

## Mocks server

The mocks directory contains a couple of static html files, and a simple server for development. Run `cd mocks && python server.py` (assuming python 2.x).
