#!/bin/bash
msg "customizing ssh daemon configuration"
cat << EOF >> /etc/ssh/sshd_config

# Setup for Docker PANDA user.
Match User $DOCKER_USER
	X11Forwarding no
	AllowTcpForwarding no
	AllowStreamLocalForwarding no
	ForceCommand $PANDA_PATH/bin/recvmssh.sh
	#StrictHostKeyChecking no
EOF

msg "restarting ssh daemon"
/etc/init.d/ssh restart
