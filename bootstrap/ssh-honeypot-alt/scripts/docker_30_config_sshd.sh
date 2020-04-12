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

# Setup for root.
Match User root
	X11Forwarding no
	AllowTcpForwarding no
	AllowStreamLocalForwarding no
	ForceCommand $PANDA_PATH/bin/recvmssh.sh root
	#StrictHostKeyChecking no
EOF
sed -E -i 's/^#?(PermitRootLogin|UsePAM).*/\1 yes/' /etc/ssh/sshd_config

msg "restarting ssh daemon"
/etc/init.d/ssh restart
