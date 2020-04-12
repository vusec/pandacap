# PANDAcap Cheatsheet

## Docker image debugging
* check PANDA binary for missing libs
  ```
  ldd /opt/panda/bin/panda-system-i386 | grep -v '=>'
  ```
  This should only report back `linux-vdso.so` and `ld-linux-x86-64.so`.

-----------------------------------------------------------

## Working with qcow2/raw images
* Shrink VM image after maintenance:
  ```
  # from guest
  ./vmshrink-prep.sh -var -homedirs -swap /root
  poweroff
  ```
  ```
  # from host
  qemu-img convert -O qcow2 -o compat=0.10 ubuntu16-planb.qcow2 ubuntu16-planb-shrunk.qcow2
  ```
* Mount qcow2 image (as root):
  ```
  modprobe nbd max_part=69
  qemu-nbd -c /dev/nbd0 ./ubuntu16-planb.qcow2
  mount /dev/nbd0p1 ./mnt
  umount mnt
  qemu-nbd -d /dev/nbd0
  ```

----------------------------------------------------------

## Assorted documentation links
* [baseimage-docker documentation][d1]
* [supervisord configuration][id2]
* [managing qemu images][d3]

[d1]: https://github.com/phusion/baseimage-docker#whats-inside-the-image
[d2]: http://supervisord.org/configuration.html
[d3]: https://documentation.suse.com/sles/11-SP4/html/SLES-all/cha-qemu-guest-inst.html#cha-qemu-guest-inst-qemu-img

