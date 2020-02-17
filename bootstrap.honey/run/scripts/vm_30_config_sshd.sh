#!/bin/bash
msg "customizing ssh daemon configuration"
sed -E -i 's/^#?(PermitRootLogin|UsePAM).*/\1 yes/' /etc/ssh/sshd_config

msg "restarting ssh daemon"
/etc/init.d/ssh restart
