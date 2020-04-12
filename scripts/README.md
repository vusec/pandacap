# PANDAcap scripts
This directory contains an assortment of scripts used by PANDAcap.

## The PANDAcap wrapper
[pandacap.py](pandacap.py)

## Other scripts
### VM base scripts
* [usbbootstrap.sh](usbbootstrap.sh): This is the script that
  implements the runtime bootstrapping for the VM. It should be
  copied somewhere in the system (e.g. `root`'s home directory)
  and called from `/etc/rc.local` using its absolute path.
* [vmshrink-prep.sh](vmshrink-prep.sh): Convenience script for
  preparing a VM image to be compacted. Requires [zsh](zsh).
  See the [PANDAcap cheatsheet](../docs/cheatsheet.md) for details.

### Runtime bootstrapping script
[bootstrap.sh](bootstrap.sh) script is used for docker and VM runtime
bootstrapping. It is soft-linked from the directories where it is used.
Its actions hould be straightforward to understand by skimming through
its code.

### Misc
* [pyrun.sh](pyrun.sh): This is a wapper for running python scripts
  used by PANDAcap inside a virtual environment.
* [honeypot.sh](honeypot.sh): This is the script used by
  [supervisord](sup) to launch new PANDAcap ssh-honeypots,
  as described in the EuroSec 2020 paper. It keeps track of how many
  honeypot instances have been launched so far, and prepares all the
  arguments required by `pandacap.py`. Implementation requires the
  intricate use of `flock` to implement mutual exclusion for the
  processes launched by supervisord.

[zsh]: http://www.google.com
[sup]: http://www.google.com

