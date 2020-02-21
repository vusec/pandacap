#!/bin/bash
msg "updating recvmssh wrapper"
cp -vf "$BOOTSTRAP_FILES_DIR"/recvmssh.sh "$PANDA_PATH/bin"
chmod -v 755 "$PANDA_PATH/bin/recvmssh.sh"
