#!/bin/sh
#
# usbbootstrap.sh
#
# This script is meant to be executed from /etc/rc.local.
# It will attempt to mount a volume labeled "bootstrap" and execute
# bootstrap.sh from it. Then, the script will remove itself so that it
# is not executed on the next boot.
# Additionally, the script will disable any USB storage devices plugged
# at the time it runs. This is because the "bootstrap" volume presumably
# resides on a USB storage device.
#

mkdir /mnt/bootstrap
if mount -L bootstrap /mnt/bootstrap 2>/dev/null; then
    if [ -x "/mnt/bootstrap/bootstrap.sh" ]; then
        # execute bootstrap script
        /mnt/bootstrap/bootstrap.sh

        # cleanup after bootstrapping
        umount /mnt/bootstrap
        find -L /sys/bus/usb/devices/ -maxdepth 2 -name product | while read f; do
            if grep -q 'QEMU USB HARDDRIVE' "$f"; then
                devid=$(echo "$f" | awk -F/ '{print $(NF-1)}')
                echo "$devid" > /sys/bus/usb/drivers/usb/unbind
            fi
        done
        sed -i "/$(basename "$0")/d" /etc/rc.local
        rm -f "$0"
    else
        # no bootstrap.sh executable - ignore
        umount /mnt/bootstrap
    fi
fi
rmdir /mnt/bootstrap

