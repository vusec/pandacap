#!/bin/bash
msg "updating recctrl wrapper"
cp -vf "$BOOTSTRAP_FILES_DIR"/recctrlu.sh /usr/local/bin
chmod -v 755 /usr/local/bin/recctrlu.sh
