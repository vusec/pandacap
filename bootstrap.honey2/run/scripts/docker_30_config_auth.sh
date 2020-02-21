#!/bin/bash
msg "customizing common-auth"
common_auth_real="/etc/pam.d/common-auth"
common_auth_temp=$(mktemp -t common_auth_XXXX)

awk '
	/pam_unix.so/ {
		print "auth	[success=2 default=ignore]	pam_succeed_if.so user = root"
	}
	// {
		print $0
	}
' "$common_auth_real" > "$common_auth_temp"

cat "$common_auth_temp" > "$common_auth_real"
rm -f "$common_auth_temp"
