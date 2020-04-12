#!/bin/bash

PANDA_BIN_FILES=()
panda_bin="$PANDA_PATH/bin"

if [ ! -d "$panda_bin" ]; then
    msg "creating %s" "$panda_bin"
    mkdir -p "$panda_bin"
fi

msg "moving files to %s" "$panda_bin"
for f in $PANDA_BIN_FILES; do
    mv -vf "$BOOTSTRAP_FILES_DIR"/"$f" "$panda_bin"/
done

msg "fixing ownership in %s" "$panda_bin"
chown -vR "$DOCKER_USER:$DOCKER_USER_GROUP" "$PANDA_PATH"

