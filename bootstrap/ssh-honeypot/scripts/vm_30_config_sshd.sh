#!/bin/bash
msg "customizing ssh daemon configuration"
for f in sshd_config ssh.txt sftp.txt; do
	cp -vf "$BOOTSTRAP_FILES_DIR"/"$f" /etc/ssh/
done
sed -E -i 's/^#?(PermitRootLogin|UsePAM).*/\1 yes/' /etc/ssh/sshd_config

msg "restarting ssh daemon"
/etc/init.d/ssh restart
