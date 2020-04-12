#!/bin/bash
# Setup startup scripts for baseimage-docker.
# See: https://github.com/phusion/baseimage-docker#running-scripts-during-container-startup

msg "adding startup scripts to /etc/my_init.d"
rsync -avPh "$BOOTSTRAP_FILES_DIR"/my_init.d/ /etc/my_init.d/

