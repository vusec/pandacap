#!/bin/bash

# Expand non-matching glob patterns to null string, rather than themselves.
shopt -s nullglob

config_user() {
	local u="$1"
	local g="$(getent group "$u" | awk -F: '{print $1}')"
	local homedir="$(getent passwd "$u" | awk -F: '{print $6}')"
	local authorized_keys="$homedir"/.ssh/authorized_keys
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
	# copy keys
	for pk in "$BOOTSTRAP_FILES_DIR"/id_*; do
		pkbase="$(basename "$pk")"
		pkdest="$homedir"/.ssh/"$pkbase"
		cp -vf "$pk" "$pkdest"
		chown -vf "$u:$g" "$pkdest"
		if [ "${pk##*.}" = "pub" ]; then
			echo "# $pkbase" >> "$authorized_keys"
			cat "$pk" >> "$authorized_keys"
			echo "" >> "$authorized_keys"
		else
			chmod 600 "$pkdest"
		fi
	done
	# copy known hosts keys
	if [ -f "$BOOTSTRAP_FILES_DIR"/known_hosts ]; then
		cp -vf "$BOOTSTRAP_FILES_DIR"/known_hosts "$known_hosts"
		chown -vf "$u:$g" "$known_hosts"
	fi
	# fix authorized_keys ownership
	if [ -f "$authorized_keys" ]; then
		chown -vf "$u:$g" "$authorized_keys"
	fi

	msg "copying rc files for user %s" "$u"
	for rc in "$BOOTSTRAP_FILES_DIR"/*shrc; do
		rcdest="$homedir"/."$(basename "$rc")"
		cp -vf "$rc" "$rcdest"
		chown -vf "$u:$g" "$rcdest"
	done

	return 0
}

config_user "$DOCKER_USER"

