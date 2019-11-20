#!/usr/bin/env zsh
# Wrapper script for running python stuff from within a virtualenv.

WRAPPER="$0"
PYTHON="python3"
PYENV="pyenv"
PYENV_ACTIVATE="$PYENV/bin/activate"
PYENV_REQUIREMENTS="requirements.txt"

function activate_pyenv() {
	pushd $(dirname $WRAPPER)
	if [ -f "$PYENV_ACTIVATE" ]; then
		. "$PYENV_ACTIVATE"
	else
		virtualenv -p "$PYTHON" "$PYENV"
		. "$PYENV_ACTIVATE"
		if [ -f "$PYENV_REQUIREMENTS" ]; then
			pip install -r "$PYENV_REQUIREMENTS"
		fi
	fi
	popd
}

activate_pyenv
$@

# vim: set tabstop=4 softtabstop=4 noexpandtab :
