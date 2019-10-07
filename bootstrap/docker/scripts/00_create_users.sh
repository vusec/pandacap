#!/bin/bash

addgroup --gid "$DOCKER_USER_GID" "$DOCKER_USER_GROUP"
adduser --uid "$DOCKER_USER_UID" --gid "$DOCKER_USER_GID" \
       --shell /bin/zsh \
       --gecos 'Docker PANDA User' \
       --disabled-password \
       "$DOCKER_USER"

