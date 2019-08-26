# Documentation
* [baseimage-docker documentation][1]
* [supervisord configuration][2]
* [managing qemu images][3]

[1]: https://github.com/phusion/baseimage-docker#whats-inside-the-image
[2]: http://supervisord.org/configuration.html
[3]: https://www.suse.com/documentation/opensuse121/book_kvm/data/cha_qemu_guest_inst_qemu-img.html
-----------------------------------------------------------

# Commands

## Docker host
* rebuild container
  ```
  docker build -t prov2r .
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

