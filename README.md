# Dockerfile for mirakc

[![ci-status](https://github.com/masnagam/docker-mirakc/workflows/Docker/badge.svg)](https://github.com/masnagam/docker-mirakc/actions?workflow=Docker)
[![Docker Pulls](https://img.shields.io/docker/pulls/masnagam/mirakc)](https://hub.docker.com/r/masnagam/mirakc)

## Build images

For amd64 machine:

```console
$ docker build .
```

Cross-build for ROCK64:

```console
$ ./build arm64
```

Build with BuildKit:

```console
$ DOCKER_BUILDKIT=1 ./build arm64
```

The `build` script creates a Docker image for the `arm64` architecture.  The
image is named and tagged with `$(id -un)/mirakc:arm64`.

An image contains the following executables:

* [recdvb] configured without `--enable-b25`
* [recpt1] configured without `--enable-b25`
* [mirakc-arib]
* [mirakc]
* [curl]
* [socat]

When running the `build` script, the executables above are cross-compiled with a
cross-compiler instead of compiling them with the QEMU user mode emulation, in
order to reduce the build time.  Compiling with the QEMU user mode emulation can
simplify `Dockerfile.cross` and makes it possible to reuse `Dockerfile` for
cross-building images probably.  But it's very slow even when running on a
powerful PC.

`Dockerfile` and `Dockerfile.cross` uses multi-stage builds for compiling the
executables.  The multi-stage builds creates untagged intermediate images like
below:

```console
$ docker images --format "{{.Repository}}:{{.Tag}}"
masnagam/mirakc:arm64
<none>:<none>
...
```

The following command removes **all untagged images** including the intermediate
images:

```console
$ docker images -f dangling=true -q | xargs docker rmi
```

The following command transfers the created image to a remote docker daemon
which can be accessed using SSH:

```console
$ docker save $(id -un)/mirakc:arm64 | docker -H ssh://remote load
```

## Launch a mirakc Docker container using `docker-compose`

See [docker-compose.yml](./docker-compose.yml) and
[sample-mirakc-config.yml](./sample-mirakc-config.yml).

## Build a custom Docker image

A custom Docker image for the linux/arm64 architecture can be built with the
following Dockerfile:

```Dockerfile
FROM masnagam/mirakc:arm64
...
```

Images for the following architectures have been uploaded to [DockerHub].

* masnagam/mirakc:amd64 (linux/amd64)
* masnagam/mirakc:armv5 (linux/arm/v5)
* masnagam/mirakc:armv7 (linux/arm/v7)
* masnagam/mirakc:arm64 (linux/arm64)

Consult [Dockerfile.cross](./Dockerfile.cross) if you like to build a Docker
image for an architecture other than the above.

## Performance

* Consume about 30MB when launching a mirakc container on ROCK64
* See [README.md](https://github.com/masnagam/mirakc/blob/master/README.md#performance-comparison)
  in the mirakc GitHub repository for details of the latest performance
  comparison with Mirakurun

## License

Licensed under either of

* Apache License, Version 2.0
  ([LICENSE-APACHE] or http://www.apache.org/licenses/LICENSE-2.0)
* MIT License
  ([LICENSE-MIT] or http://opensource.org/licenses/MIT)

at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in this project by you, as defined in the Apache-2.0 license,
shall be dual licensed as above, without any additional terms or conditions.

[recdvb]: http://cgi1.plala.or.jp/~sat/?x=entry:entry180805-164428
[recpt1]: https://github.com/stz2012/recpt1
[mirakc-arib]: https://github.com/masnagam/mirakc-arib
[mirakc]: https://github.com/masnagam/mirakc
[curl]: https://curl.haxx.se/docs/manpage.html
[socat]: http://www.dest-unreach.org/socat/doc/socat.html
[DockerHub]: https://hub.docker.com/r/masnagam/mirakc/tags
[LICENSE-APACHE]: ./LICENSE-APACHE
[LICENSE-MIT]: ./LICENSE-MIT
