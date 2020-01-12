#!/usr/bin/env zsh
#
# vmshrink-prep.sh
#
# A script to prepare virtual machines for shrinking.
# This includes cleaning up various locations as well as recreating the
# swap file. After running the script, shutdown the VM and use qemu-img
# to create a shrinked copy of the image:
# qemu-img convert -O qcow2 -o compat=0.10 prepared.qcow2 shrinked.qcow2
#

SCRIPT="$(basename "$0")"

function var_cleanup() {
    echo "Cleaning up var files..."
    find /var/log -type f -name '*.gz' -print -delete
    find /var/log -type f -name '*.1' -print -delete
    find /var/log -type f -print -exec cp /dev/null \{\} \;
    find /var -type f -name '*-old' -print -delete
}

function homedirs_cleanup() {
    local flist=(.bash_history .cache .python_history .sudo_as_admin_successful .viminfo .ssh/authorized_keys)
    for d in /root /home/*; do
        echo "Cleaning up files in $d..."
        for f in $flist; do
            rm -rvf "$d/$f"
        done
    done
}

function swap_wipe() {
    local processed_swap=0
    swapon --show=NAME,UUID | tail -n +2 | while read dev uuid; do
        echo "Clearing swap on $dev..."
        swapoff -U $uuid
        dd if=/dev/zero of="$dev" bs=8192
        mkswap -L "swap$processed_swap" -U $uuid $dev
        swapon -U $uuid
        let processed_swap++
    done
}

zparseopts -D -E -a opts -- help swap var homedirs

if ((${opts[(I)-help]})); then
    echo "Script for preparing VM disks for shrinking/compacting."
    echo "Usage: $SCRIPT [-help] [-var] [-homedirs] [-swap] dir1 dir2 ..."
    exit 1
fi

if [ "$(uname -s)" != "Linux" ]; then
    echo "Unsupported OS: $(uname -s)."
    exit 1
fi

if ((${opts[(I)-var]})); then
    var_cleanup
fi

if ((${opts[(I)-homedirs]})); then
    homedirs_cleanup
fi

if ((${opts[(I)-var]})); then
    swap_wipe
fi

processed=0
for d in "$@"; do
    if [ ! -d "$d" ]; then
        echo "skipping $d (not a dir)"
        continue
    fi
    echo "processing $d"
    wipefile="$d"/wipe"$RANDOM"
    dd if=/dev/zero of="$wipefile" bs=8192
    rm -rf "$wipefile"
    (( processed++ ))
done

if (( processed > 0 )); then
    echo ""
    echo "Processed $processed directories."
else
    echo "No filesystems processed."
fi

