# Bootstrap files

The files in this directory are used in different bootstrapping phases of
a __NAME__ setup.

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
