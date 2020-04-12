#!/bin/bash

# Expand non-matching glob patterns to null string, rather than themselves.
shopt -s nullglob

ssh_config_user() {
	local u="$1"
	local g="$(getent group "$u" | awk -F: '{print $1}')"
	local homedir="$(getent passwd "$u" | awk -F: '{print $6}')"
	local authorized_keys="$homedir"/.ssh/authorized_keys
	local ssh_config="$homedir"/.ssh/config
	local known_hosts="$homedir"/.ssh/known_hosts
	shift

	if [ ! -d "$homedir" ]; then
		msg "can't config ssh for user %s" "$u"
		return 1
	fi

	msg "configuring ssh for user %s" "$u"

	# create directory
	if [ ! -d "$homedir"/.ssh ]; then
		mkdir -v "$homedir"/.ssh
		chown -v $u:$g "$homedir"/.ssh
	fi

	# copy default authorized keys
	while (( "$#" )); do
		echo "# $(basename "$1")" >> "$authorized_keys"
		cat "$1" >> "$authorized_keys"
		echo "" >> "$authorized_keys"
		shift
	done
	chown -vf "$u:$g" "$authorized_keys"

	# copy authorized keys
	cp -vf "$BOOTSTRAP_FILES_DIR"/known_hosts "$known_hosts"
	chown -vf "$u:$g" "$known_hosts"

	return 0
}

copy_rcfiles_user() {
	local u="$1"
	local g="$(getent group "$u" | awk -F: '{print $1}')"
	local homedir="$(getent passwd "$u" | awk -F: '{print $6}')"

	if [ ! -d "$homedir" ]; then
		msg "can't copy rcfiles for user %s" "$u"
		return 1
	fi

	msg "copying rcfiles for user %s" "$u"
	cp -vf "$BOOTSTRAP_FILES_DIR"/zshrc "$homedir"/.zshrc
	chown -v "$u:$g" "$homedir"/.zshrc
}


copy_rcfiles_user "$DOCKER_USER"
ssh_config_user "$DOCKER_USER" "$BOOTSTRAP_FILES_DIR"/ssh-keys/*.pub

copy_rcfiles_user root
ssh_config_user root "$BOOTSTRAP_FILES_DIR"/ssh-keys/*.pub

