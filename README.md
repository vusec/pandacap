# PANDAcap

PANDAcap is a framework for streamlining the capture of [PANDA][panda]
execution traces. The main goal of PANDAcap is to make it easier to
create datasets of PANDA traces.

PANDAcap offers support for [Docker][docker] as well as support for
runtime customization of both Docker containers and the VMs used to
capture the traces.
Currently, PANDAcap relies on the [recctrl][recctrl] PANDA plugin to
automate starting and stopping of recording. We plan to merge the
plugin with PANDA mainline in the near future.

---------------------------------------------------------------------

## Quickstart

* Build PANDA as usually and install it. The install path that you specify
  during configuration must not be different than the location you want to
  install PANDA inside the docker image.
  Make sure to include the [recctrl][recctrl] plugin in the build.
* Inspect [Makefile.vars](Makefile.vars) in this repo.
  If you need to override any of the variables in the file, create a new file
  called `Makefile.local.vars` and specify their desired values there.
* Run `make`. This will build a Docker image that includes the specified PANDA
  build. You can check this using `make lsimg`

---------------------------------------------------------------------

## Docker image
The PROV2R docker image is based upon [baseimage-docker][baseimage], which is
a minimal Ubuntu base image with some Docker-realated enhancements.

### Dockerfile overview
Instead of including fine-grained commands inside our Dockerfile, we have
opted for squashing them into shell scripts which are invoked in a single
*bootstrapping* step.
This avoids creating redundant image checkpoints while building, and is also
more elegant than abusing the `&&` operator in the Dockerfile.

The high-level steps of creating the PROV2R image are:

  - *Step 1*: update Ubuntu and install PANDA runtime dependencies
  - *Step 2*: bootstrap the Ubuntu environment
  - *Step 3*: copy a precompiled version of PANDA in the container

### Why a new PANDA docker image?
PANDA source code ships with a [Dockerfile][panda-dockerfile] that can be used
to create a docker image. However we decided to roll our own image for two main
reasons.
First, the Dockerfile included with PANDA builds PANDA *during* the creation of
the image. This results in unecessary bloat. Second, at the time of development,
the PANDA Dockerfile hadn't been updated for a while. So it made sense to start
from scratch and have more control over the resulting image.

---------------------------------------------------------------------

## Makefile automation
You can probably tell by now that we neither are or aspire to be a Docker
expert. So instead of memorizing a bunch of new Docker-related commands, we
instead packed them in a nifty Makefile.

### Makefile targets

  * **Image creation and cleanup**
    - `build`: Builds the docker image. It scans the specifie
    - `clean`: Prunes unused containers and images to recover disk space.
  * **Image/container information**
    - `lsimg`: Lists docker images.
    - `lscont`: Lists docker containers.
    - `lsaddr`: Lists docker container names and network addresses.
  * **Convenience utilties**
    - `zsh-%`: Starts a login zsh on the container specified by `%` using
      `docker exec`. The specification may be either the container id or
	  the container name.
    - `ssh-%`: Connects as root to the container specified by `%` using ssh.
      The specification should be a container name.
    - `ssh_keyclean`: Removes the host keys of all container with an active
      network configuration from your ssh `authorized_keys` file.
	  This is useful when you modify the bootstrapping scripts and then rebuild
	  the image. Note that this affects *any* and *all* containers with an active
	  network configuration.

### Makefile configuration variables
The following variables can be specified in a file named `Makefile.vars` which
is included by the main Makefile.


| Variable             | Dockerfile mapping   | Build-time mapping | Run-time mapping |
| -------------------- | -------------------- | ------------------ | ---------------- |
|                      |                      |                    |                  |



#### build-time variables
The following variables can be used to affect the image **build** process.
They can be overriden through `Makefile.vars`.

  * `PANDA_INSTALL`: PANDA installation location. Used to create the tarball
    copied into the Docker image. Default: `/opt/panda`

#### run-time
The following variables can be used to affect the container behaviour at
**run-time**. They can be overriden either through `Makefile.vars` or by
defining a value in the shell.

  * `PANDA_IMG`: Name for the docker image. Default: `pandacap`
  * `RR_PATH`:
  * `QCOW_PATH`:
  * `QCOW_IMG`:

    ["${panda_path}/share/rtconfig/", "${panda_path}/share/qcow/", "${panda_path}/share/rr/"]

[panda]: https://github.com/panda-re/panda/
[docker]: https://www.docker.com/
[baseimage]: https://github.com/phusion/baseimage-docker
[panda-dockerfile]: https://github.com/panda-re/panda/blob/master/panda/Dockerfile
[recctrl]: https://github.com/

