# PANDAcap – SSH Honeypot Dataset

## Overview
This is a dataset of **63 [PANDA][panda] traces**, collected using the
[PANDAcap][pandacap] framework.
The dataset aims to offer a starting point for the analysis of *ssh
brute force attacks*.
The traces were collected through the  course of approximately 3 days
from 21 to 23 February 2020.
A VM was configured using PANDAcap so that it accepts all passwords for
user `root`. When an ssh session starts for the user, PANDA is signaled
by the [recctrl plugin][recctrl] to start recording for 30'.

You can read more details about the experimental setup and an overview
of the dataset **EuroSec 2020** publication:

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

## Dataset layout
The dataset is split in 3 zip files/directories:
* **rr**: Contains the 63 PANDA traces of the dataset. The traces are in the
  upcoming RRArchive format. Note that PANDA support for the format is still
  wip at the time of writing (April 2020). If you need to downgrade to the
  traditional PANDA trace format, you can use [this snippet][a-trace-convert].
* **qcow**: Contains the QCOW base image (`ubuntu16-planb.qcow2`) used to create
  the dataset, as well as the disk deltas for the 63 traces. These can be mounted
  to inspect the contents of the filesystem before and after each session.
  and disk deltas for the 63 traces. Quick instructions on how to mount
  and inspect a QCOW image can be found [below][mounting-a-qcow-image].
* **pcap**: Contains the pcap network traces for the sessions in the PANDA traces.
  These have been extracted using the PANDA [network plugin][network]. We decided
  to also include them in the dataset as standalone files for convenience.

Additionally, we provide the PANDA linux kernel profile `ubuntu16-planb-kernelinfo.conf`,
which can be used to analyze the traces using the PANDA [osi_linux plugin][osi_linux].

If you wish to reuse the VM image in your project, it is also available as a standalone
download through [academictorrents.com][at-vm-url], along with more detailed information
on its contents.

## Handy snippets

### Convert traces to traditional PANDA format
From inside the `rr` directory, run:

```bash
for f in *.tar.gz; do
    tar -zxvf "$f" --exclude=PANDArr --xform='s%/%-%' --xform='s%-metadata%%'
    rm -f "$f"
done
```

### Mounting a QCOW image
Run the following as root:
```bash
modprobe nbd max_part=69
qemu-nbd -c /dev/nbd0 ./ubuntu16-planb.qcow2
mount /dev/nbd0p1 ./mnt
# ...do some work...
umount mnt
qemu-nbd -d /dev/nbd0
```

[a-trace-convert]: #convert-traces-to-traditional-panda-format
[a-qcow-mount]: #mounting-a-qcow-image
[at-vm-url]: https://academictorrents.com/details/39df3904460e909e175434cbd87764b8c487891d
[eurosec20-doi]: https://doi.org/10.1145/3380786.3391396
[eurosec20-preprint]: https://www.vusec.net/publications/#stamatogiannakis-bos-groth-pandacapaframeworkforstreamliningcollectionoffullsystemtraces-2020
[eurosec20-www]: https://www.concordia-h2020.eu/eurosec-2020/
[osi_linux]: https://github.com/panda-re/panda/tree/master/panda/plugins/osi_linux
[panda]: https://github.com/panda-re/panda
[pandacap]: https://github.com/vusec/pandacap
[qcow]: https://en.wikipedia.org/wiki/Qcow
[qcow-cheat]: https://github.com/vusec/pandacap/blob/master/docs/cheatsheet.md#working-with-qcow2raw-images
[network]: https://github.com/panda-re/panda/tree/master/panda/plugins/network
[recctrl]: https://github.com/panda-re/panda/tree/master/panda/plugins/recctrl
[recctrlu]: https://github.com/panda-re/panda/tree/master/panda/plugins/recctrl/utils

