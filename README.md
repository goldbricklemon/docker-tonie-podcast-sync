[![Docker Image Version](https://img.shields.io/docker/v/goldbricklemon/tonie-podcast-sync?sort=semver&arch=amd64&style=flat&logo=docker&label=Docker%20Hub%20Version&labelColor=383838)](https://hub.docker.com/repository/docker/goldbricklemon/tonie-podcast-sync/general)
<br>
[![Docker Build & Publish](https://github.com/goldbricklemon/docker-tonie-podcast-sync/actions/workflows/docker-release-publish.yml/badge.svg)](https://github.com/goldbricklemon/docker-tonie-podcast-sync/actions/workflows/docker-release-publish.yml)

# docker-tonie-podcast-sync
A Docker container to sync podcast episodes to Creative Tonies for the [Toniebox](https://tonies.com/en-gb/tonieboxes/).

On DockerHub: https://hub.docker.com/r/goldbricklemon/tonie-podcast-sync

This is a kind-of-minimal container around the [tonie-podcast-sync](https://github.com/alexhartm/tonie-podcast-sync) CLI/Python tool by [alexhartm](https://github.com/alexhartm). It allows you to sync podcast episodes (e.g. the newest ones) to your Creative Tonies on a cron schedule.

This is a purely private project and has no association with Boxine GmbH.

## Why?

Truth be told, this container is pretty much a glorified containerized `cron` that periodically calls `tonie-podcast-sync`. Why did I build a container image just for that?

  1. I like to run most of my stuff at home via Docker
  2. I dislike to directly install and/or cron-schedule stuff (or run [services](https://github.com/alexhartm/tonie-podcast-sync/issues/27)) on my host machines, if it does not directly address the host itself (e.g. backups or the like)
  3. Getting into the intricacies of running cron inside a Docker container is a fun weekend read/project.


## Running

This can be run using a docker compose file or a standard docker run command. But you need to setup your `tonie-podcast-sync` settings first and pass them into the container appropriately.

### Create Settings
The container is built to run `tonie-podcast-sync` with existing settings (i.e. which podcast(s) to sync to which Creative Tonie). It is not intended to generate those settings using the interactive CLI setup of `tonie-podcast-sync` (although you could get away by `exec -it` into the container and running the setup there). 

My recommendation: temporarily `pip install tonie-podcast-sync` on your machine and follow the [setup instructions](https://github.com/alexhartm/tonie-podcast-sync?tab=readme-ov-file#via-cli). This generates the following setting files:

```
~/.toniepodcastsync
  L settings.toml
  L .secrets.toml (optional)
```

Transfer those files (or just the entire directory) to your Docker host. If you want to change your podcast sync settings later, either re-do those steps or just directly edit the `settings.toml`.

### Run Container
Running the container requires you to specify the cron schedule at which the sync is running via the environment variable `CRON_SCHEDULE`, e.g.:

`docker run [...] --env CRON_SCHEDULE="0 8 * * *" [...]`

You further need to inject the `settings.toml` as well as your Tonie Cloud credentials. The container offers two variants to do that.

#### A)
I case you want to pass your credentials via the
`.secrets.toml` file into the contianer, just
bind-mount the complete `.toniepodcastsync` directory. This obviously **requires** the `.secrects.toml` file to be present.

The minimal `docker run` command would look like this:

```
docker run -d \
--mount type=bind,src=.toniepodcastsync,dst=/root/.toniepodcastsync,readonly \
--env CRON_SCHEDULE="0 8 * * *" \
goldbricklemon/tonie-podcast-sync:latest
```

#### B)
If you don't want to persist your credentials on your host machine in a `.secrets.toml` file, you can alternatively pass them as environment variables as well. Just make sure to still bind-mount your `settings.toml`, **BUT ONLY THIS FILE, not the entire `.toniepodcastsync` directory**.

The minimal `docker run` command would look like this:

```
docker run -d \
--mount type=bind,src=.toniepodcastsync/settings.toml,dst=/root/.toniepodcastsync/settings.toml,readonly \
--env TONIE_CLOUD_USERNAME="<your-tonie-cloud-email>" \
--env TONIE_CLOUD_PASSWORD="<your-password>" \
--env CRON_SCHEDULE="0 8 * * *" \
 goldbricklemon/tonie-podcast-sync:latest
```

In both cases, you can edit your `settings.toml` on the host (change podcasts, new creative tonie, etc.), and the bind-mount will make those changes visible to the container.

You can obviously use `docker-compose` as well, no surprises there. There is also the option `TONIE_CLOUD_SYNC_NOW` to always run a sync on container startup, which can help in testing your setup (see below).

### Overview Environment Variables

| Env Var               | Value                                   | Comment                                                                                                                                   |
|----------------------|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| CRON_SCHEDULE        | A valid cron schedule, e.g. "0 8 * * *" |                                                                                                                                           |
| TONIE_CLOUD_SYNC_NOW | Any value will set this to `true`       | If this env var is set (any value), the container will perform one sync right at start-up, before handing things over to the cron schedule |
| TONIE_CLOUD_USERNAME | Tonie Cloud username (e-mail)           | Only required, if no `.secrets.toml` is passed to the container                                                                           |
| TONIE_CLOUD_PASSWORD | Tonie Cloud password                    | Only required, if no `.secrets.toml` is passed to the container                                                                           |


### Container Variant `-noffmpeg`

The regular container version comes with `ffmpeg` installed, to support the podcast-trimming feature of `tonie-podcast-sync`. This comes at the price of making the container image unreasonably large. Hence, the `-noffmpeg` varaint of the container with no `ffmepg` installed. Just don't use it if you make use of podcast trimming.

## Open TODOs
  * ~~Add multi-arch support/build (gotta cover the Raspberry folks out there)~~
  * ~~Sanity checks on container start-up to ensure correct usage of parameters~~
  * The container image is currently far too large for what it brings. Options:
    + ~~Offer a non-`ffmpeg` version~~
    + Migrate to `alpine` (although python applications under `alpine` can be iffy)
  * Run as non-root user
    
## Builds Upon / Thanks To
- moritj29's [tonie_api](https://github.com/moritzj29/tonie_api)
- alexhartm's [tonie-podcast-sync](https://github.com/alexhartm/tonie-podcast-sync)
