# Documentation
* [baseimage-docker documentation][1]
* [supervisord configuration][2]
* [managing qemu images][3]

[1]: https://github.com/phusion/baseimage-docker#whats-inside-the-image
[2]: http://supervisord.org/configuration.html
[3.old]: https://www.suse.com/documentation/opensuse121/book_kvm/data/cha_qemu_guest_inst_qemu-img.html
[3]: https://documentation.suse.com/sles/11-SP4/html/SLES-all/cha-qemu-guest-inst.html#cha-qemu-guest-inst-qemu-img
-----------------------------------------------------------

# Commands

## Docker host
* rebuild container
  ```
  docker build -t pandacap .
  ```
* docker cleanup & reclaim space
  ```
  docker container prune
  docker image prune
  ```

## Docker container
* check binary for missing libs
  ```
  ldd /opt/panda/bin/panda-system-i386 | grep -v '=>'
  ```
  This should only report back `linux-vdso.so` and `ld-linux-x86-64.so`.

## Working with qcow2/raw images
* Run wrapper in maintenance mode:
  ```
  export PATH="/opt/panda/bin:$PATH"
  ./scripts/pandacap.py -vvv -d $HOME/spammer/panda-qcow/ubuntu16-planb.qcow2 --port-fwd=ssh:10000 maint
  ```
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
  modprobe nbd max_part=63
  qemu-nbd -c /dev/nbd0 ./ubuntu16-planb.qcow2
  mount /dev/nbd0p1 ./mnt
  umount mnt
  qemu-nbd -d /dev/nbd0
  ```

## Working with the PANDAcap wrapper
* Record a single session:
  ```
  export CAPID=run.1
  cd bootstrap/run
  make $CAPID
  cd ../..
  mkdir -p "$HOME/spammer/rr/$CAPID"
  ./scripts/pandacap.py -vvv \
    -d $HOME/spammer/panda-qcow/ubuntu16-planb.qcow2 \
    --port-fwd=ssh:10000 --port-fwd=sftp:10001 \
    --docker-image=pandacap --docker-port-fwd='20000:22:*:tcp' --docker-port-fwd='20001:10001:*:tcp' \
    -M rr:"$HOME/spammer/rr/$CAPID" \
    -M qcow:"$HOME/spammer/panda-qcow" -M bootstrap:./bootstrap/run/$CAPID/docker \
    rec --usbdisk=./bootstrap/run/$CAPID/vm --panda="recctrl:session_rec=y,nrec=1"
  ```


