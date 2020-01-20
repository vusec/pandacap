#!/bin/bash

# Expand non-matching glob patterns to null string, rather than themselves.
shopt -s nullglob

config_user() {
	local u="$1"
	local g="$(getent group "$u" | awk -F: '{print $1}')"
	local homedir="$(getent passwd "$u" | awk -F: '{print $6}')"
	local authorized_keys="$homedir"/.ssh/authorized_keys
	local ssh_config="$homedir"/.ssh/config
	local known_hosts="$homedir"/.ssh/known_hosts
	shift

	if [ ! -d "$homedir" ]; then
		msg "can't config user %s" "$u"
		return 1
	fi

	msg "configuring ssh for user %s" "$u"
	# create directory
	if [ ! -d "$homedir"/.ssh ]; then
		mkdir -v "$homedir"/.ssh
		chown -v $u:$g "$homedir"/.ssh
	fi
	# add authorized keys
	for pk in "$BOOTSTRAP_FILES_DIR"/id_*.pub; do
		echo "# $(basename "$pk")" >> "$authorized_keys"
		cat "$pk" >> "$authorized_keys"
		echo "" >> "$authorized_keys"
	done
	chown -vf "$u:$g" "$authorized_keys"
	# copy known hosts keys
	if [ -f "$BOOTSTRAP_FILES_DIR"/known_hosts ]; then
		cp -vf "$BOOTSTRAP_FILES_DIR"/known_hosts "$known_hosts"
		chown -vf "$u:$g" "$known_hosts"
	fi

	msg "copying rc files for user %s" "$u"
	for rc in "$BOOTSTRAP_FILES_DIR"/*shrc; do
		rcdest="$homedir"/."$(basename "$rc")"
		cp -vf "$rc" "$rcdest"
		chown -vf "$u:$g" "$rcdest"
	done

	return 0
}

config_user "$VM_USER"

