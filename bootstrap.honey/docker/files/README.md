# Container Image Bootstrap Files

This directory contains the files used to bootstrap the docker image.
Brief description follows.

* `my_init.d`: Scripts that are executed when a docker container starts.
  This is where you should hook any container runtime-initialization.
  See the [baseimage documentation][baseimage-init] for details.
* `ssh-keys`: Assorted ssh keys.

[baseimage-init]: https://github.com/phusion/baseimage-docker#running-scripts-during-container-startup
