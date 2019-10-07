#!/bin/bash
# Wrapper script for executing a number of scripts in sequence.

# Expand non-matching glob patterns to null string, rather than themselves.
shopt -s nullglob

msg() {
    local fmt="$1"
    shift
    printf "\e[32m%s:\e[0m \e[1m$fmt\e[0m\n" $(basename "$0") $@ >&2
}

err() {
    local fmt="$1"
    shift
    printf "\e[31m%s:\e[0m \e[1m$fmt\e[0m\n" $(basename "$0") $@ >&2
}

# base shared configuration
export -f msg err
export BOOTSTRAP_DIR=$(readlink -f $(dirname "$0"))
export BOOTSTRAP_SCRIPTS_DIR="$BOOTSTRAP_DIR"/scripts
export BOOTSTRAP_FILES_DIR="$BOOTSTRAP_DIR"/files
export BOOTSTRAP_ENV="$BOOTSTRAP_DIR"/bootstrap.env

# check directories
if [ ! -d "$BOOTSTRAP_DIR" ]; then
    err "%q is not a directory." "$BOOTSTRAP_DIR"
    exit 1
fi
if [ ! -d "$BOOTSTRAP_SCRIPTS_DIR" ]; then
    err "%q is not a directory." "$BOOTSTRAP_SCRIPTS_DIR"
    exit 1
fi
if [ ! -d "$BOOTSTRAP_FILES_DIR" ]; then
    err "%q is not a directory." "$BOOTSTRAP_FILES_DIR"
    exit 1
fi

# load env
if [ -f "$BOOTSTRAP_ENV" ]; then
    msg "using env file %q" "$BOOTSTRAP_ENV"
    . "$BOOTSTRAP_ENV"
fi

# execute bootstrap scripts
for f in "$BOOTSTRAP_SCRIPTS_DIR"/[0-9]*.sh; do
    msg "running %s" "$f"
    "$f"
done

# cleanup - make sure we're not in a repo!
if [ "$BOOTSTRAP_CLEAN" = "y" ]; then
    msg "removing bootstrap files from %s" "$BOOTSTRAP_DIR"
    rm -rf "$BOOTSTRAP_DIR"
fi

