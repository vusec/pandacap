# PANDAcap – Ubuntu 16.04 QCOW

## Overview

This is the [QCOW][qcow] disk image used in our **EuroSec 2020**
publication about the **[PANDAcap][pandacap]** framework:

  * Manolis Stamatogiannakis, Herbert Bos, and Paul Groth.
    PANDAcap: A Framework for Streamlining Collection of Full-System Traces.
    In *Proceedings of the 13th European Workshop on Systems Security*,
    [EuroSec '20][eurosec20-www], Heraklion, Greece, April 2020.
    doi: [10.1145/3380786.3391396][eurosec20-doi],
    preprint: [vusec.net][eurosec20-preprint]

    <details><summary>bibtex (paper)</summary>

    ```bibtex
    @inproceedings{pandacap-eurosec20,
    author = {Stamatogiannakis, Manolis and Bos, Herbert and Groth, Paul},
    title = {{PANDAcap: A Framework for Streamlining Collection of Full-System Traces}},
    booktitle = {Proceedings of the 13th European Workshop on Systems Security},
    series = {EuroSec '20},
    year = {2020},
    month = {April},
    address = {Heraklion, Greece},
    url = {https://doi.org/10.1145/3380786.3391396},
    doi = {10.1145/3380786.3391396},
    keywords = {framework, PANDA, record and replay, docker, honeypot, dataset},
    }
    ```

    </details>

    <details><summary>bibtex (dataset)</summary>

    ```bibtex
    @dataset{pandacap-eurosec20-dataset,
    author = {Stamatogiannakis, Manolis and Bos, Herbert and Groth, Paul},
    title = {PANDAcap SSH Honeypot Dataset},
    year = {2020},
    month = {April},
    publisher = {Zenodo},
    version = {1.0},
    url = {https://doi.org/10.5281/zenodo.3759652}
    doi = {10.5281/zenodo.3759652},
    }
    ```

    </details>


The VM image itself can be downloaded from [academictorrents.com][at-vm-url].

## Image details

### Generic information

* Installed operating system: Ubuntu 16.04 LTS
* Kernel image: `linux-image-4.4.0-130-generic`
* Last software update: 17 Feb 2020
* Login credentials: `panda:panda`
* The image has been scrubbed and compacted to reduce its size and make
  it ready for reuse in other projects.
* A [PANDA][panda] kernel profile for use with the [osi_linux][osi_linux]
  plugin is included: `ubuntu16-planb-kernelinfo.conf`

### Modifications related to PANDAcap

The image contains some modifications related to [PANDAcap][pandacap],
as listed below.

* [`recctrlu`][recctrlu] has been installed in `/usr/local/sbin`.
* [`recctrlu.sh`][recctrlu] has been installed in `/usr/local/bin`.
* `recctrlu.sh` has been hooked to `/etc/pam.d/sshd`.
  If the PANDA [`recctrl`][recctrl] plugin is active, this will trigger
  PANDA to start recording after a successful ssh login.
* `rc.local` will run `/root/usbbootstrap.sh` at boot-time.
  This will run runtime bootstrapping scripts when the image boots,
  and then clean-up after itself.

### Removing PANDAcap modifications

The PANDAcap-related modification should not affect the use of the image
for most other purposes. If needed, they can be removed as following.

```bash
sudo sed -i '/recctrlu.sh/d' /etc/pam.d/sshd
sudo rm -f /usr/local/{,s}bin/recctrlu*
sudo sed -i '/usbbootstrap.sh/d' /etc/rc.local
sudo rm /root/usbbootstrap.sh
```

[at-vm-url]: https://academictorrents.com/details/39df3904460e909e175434cbd87764b8c487891d
[eurosec20-doi]: https://doi.org/10.1145/3380786.3391396
[eurosec20-preprint]: https://www.vusec.net/publications/#stamatogiannakis-bos-groth-pandacapaframeworkforstreamliningcollectionoffullsystemtraces-2020
[eurosec20-www]: https://www.concordia-h2020.eu/eurosec-2020/
[osi_linux]: https://github.com/panda-re/panda/tree/master/panda/plugins/osi_linux
[panda]: https://github.com/panda-re/panda
[pandacap]: https://github.com/vusec/pandacap
[qcow]: https://en.wikipedia.org/wiki/Qcow
[recctrl]: https://github.com/panda-re/panda/tree/master/panda/plugins/recctrl
[recctrlu]: https://github.com/panda-re/panda/tree/master/panda/plugins/recctrl/utils
