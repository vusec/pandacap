#!/bin/sh

bd="$PANDA_PATH"/share/bootstrap
printf "Using bootstrap directory '%s'.\n" "$bd" >&2

if [ -x "$bd"/bootstrap.sh ]; then
	"$bd"/bootstrap.sh
else
	printf "No bootstrap.sh found. Did you forget to mount the bootstrap directory at runtime?\n" >&2
fi

