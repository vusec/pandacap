#!/bin/bash
# recctrlu wrapper script.
# Allows easier integration of the utility with pam.d.

RECCTRL=/usr/local/sbin/recctrlu
USERS=(panda root)

# Check that PAM variables are set and PAM_USER matches.
[ "$PAM_USER" != "" ] || exit 10
[ "$PAM_TYPE" != "" ] || exit 11
[[ " ${USERS[@]} " =~ " ${PAM_USER} " ]] || exit 12

${RECCTRL} ${PAM_TYPE} ${PAM_USER}_session
