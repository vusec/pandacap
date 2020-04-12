# Runtime bootstrap directories

This directory contains different runtime bootstrap configurations
for PANDAcap. Edit `Makefile.vars` to make `DOCKER_BOOTSTRAP` and
`RUNTIME_BOOTSTRAP` variables to point to the directories you want
to use.

## Available configurations
The currently available configurations are:

* [ssh-honeypot](ssh-honeypot): The configuration used for the EuroSec 2020
  PANDAcap paper.
* [ssh-honeypot-alt](ssh-honeypot-alt): An alternative configuration for an
  ssh honeypot. The goal was to also include [asciinema](asciinema) recording
  of the ssh sessions. We abandoned this feature because the setup didn't work
  well with sftp connections.
* [prov2r-dataset](prov2r-dataset): Configuration for the collection of a 
  provenance dataset based on [PROV2r][prov2r]. (WIP)

If you use PANDAcap and want to include your configuration here, feel free
to send a pull request.

## Layout for new configurations
* [`docker`](docker) → **Docker image bootstrapping**.
  This includes installing support for the runtime bootstrapping of the
  containers instatiated from the image.
  The files in this directory are packed in a tarball and copied into the
  Docker image. Then, `bootstrap.sh` is invoked to complete the bootstrapping
  process. This approach allows squashing bootstrapping in a single `RUN`
  instruction in the `Dockerfile`.
  The location of the directory can be overriden by setting `DOCKER_BOOTSTRAP`
  in your `Makefile.local.vars`.
* [`vm`](vm) → **PANDA VM image bootstrapping**. Installation is manual.
  The scripts provide support for runtime bootstrapping of the VM, plus
  some convenience functions for VM maintenance. If you don't need runtime
  bootstrapping for yours setup, you may skip installation.
* [`run`](run) → **Runtime bootstrapping for Docker container and PANDA VM**.

[prov2r]: http://www.google.com
[asciinema]: http://www.google.com

