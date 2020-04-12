# PANDAcap

<img src="docs/pandcap-logo-bw.png" align="right" height="120" width="120"/>

PANDAcap is a framework for streamlining the capture of [PANDA][panda]
execution traces. The main goal of PANDAcap is to make it easier to
**create datasets of PANDA traces**.
PANDAcap offers support for [Docker][docker] as well as support for
runtime customization of both Docker containers and the VMs used to
capture the traces.
It relies on the [recctrl][recctrl] PANDA plugin to automate starting
and stopping of recording. The plugin has been developed for use with
PANDAcap and later merged with the PANDA mainline.

You can read more about PANDAcap in our **EuroSec 2020 paper**:

  * Manolis Stamatogiannakis, Herbert Bos, and Paul Groth.
    PANDAcap: A Framework for Streamlining Collection of Full-System Traces.
    In *Proceedings of the 13th European Workshop on Systems Security*,
    [EuroSec '20][eurosec20-www], Heraklion, Greece, April 2020.
    doi: [10.1145/3380786.3391396][eurosec20-doi],
    preprint: [TBA][eurosec20-preprint]

    <details><summary>bibtex</summary>

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

You can download the **ssh honeypot dataset** of PANDA traces from
the EuroSec paper from one of the following links.

  * EuroSec 2020 ssh honeypot dataset
  * ssh honeypot – [VM image](docs/eurosec20-vm.md) only:
    [academictorrents.com][at-vm-url]

**Note:** Good documentation is hard to do. If a piece of information
seems to be missing or is not clear enough, feel free to use the
[issue tracker](https://github.com/vusec/pandacap/issues) or contribute
a [pull request](https://github.com/vusec/pandacap/pulls).
  
---------------------------------------------------------------------

## Quickstart

  * Build PANDA as usually and install it. The install path that you
    specify during configuration must not be different than the
    location you want to install PANDA inside the docker image.
    Make sure to include the [recctrl][recctrl] plugin in the build.
  * Inspect [Makefile.vars](Makefile.vars) in this repo. Documentation
    for the use of each variable is provided in the comments.
  * If you need to override any of the variables in the file, create
    a new file called `Makefile.local.vars` and specify their desired
    values there.
  * Run `make`. This will build a Docker image that includes the
    specified PANDA build. You can check this using `make lsimg`.
  * Running `make help` will you provide an overview of what actions
    can be performed via the Makefile.
  * Run `./scripts/pandacap.py --help` to get help on the PANDAcap wrapper.

---------------------------------------------------------------------

## Docker image
PANDAcap builds a docker image based on [baseimage-docker][baseimage],
a minimal Ubuntu-based image with some Docker-realated enhancements.
The purpose of the image is to provide a self-contained environment for
recording PANDA traces.

### Dockerfile overview
Instead of including fine-grained commands inside our Dockerfile, we
have opted for squashing them into shell scripts which are invoked in
a single *bootstrapping* step.
This avoids creating redundant image checkpoints while building, and
is also more elegant than abusing the `&&` operator in the Dockerfile.

The high-level steps of creating a PANDAcap Docker image are:

  - *Step 1*: update Ubuntu and install PANDA runtime dependencies
  - *Step 2*: bootstrap the Ubuntu environment
  - *Step 3*: copy a precompiled version of PANDA in the container

### Why a new PANDA docker image?
PANDA source code ships with a couple of
[Dockerfiles][panda-dockerfile] that can be used to create a Docker
image. However these docker files are mostly intended for *building*
PANDA in a reproducible environment. This means that a lot of
build-time dependencies are dragged in the resulting image, causing
unecessary bloat. We felt that for creating a dataset with PANDA, a
leaner image that includes only what is required to run PANDA would be
preferrable.

---------------------------------------------------------------------

## Makefile ❤️

### Makefile commands
While we appreciate the convenience offered by Docker, we recognize
that we are probably only going to need it occasionally in our
research field. For this, in addition to the functionality wrapped in
the `pandacap.py` script, we have packed several useful Docker-related
commands in the main PANDAcap Makefile. Some of the available commands
are presented below. Running `make help` provides an overview of all
the available commands. 

  * **Image creation and cleanup**
    - `build`: Builds the docker image. It scans the specifie
    - `clean-docker`: Prunes unused containers and images to recover
       disk space.
    - `clean-files`: Removes intermediate files, forcing them to be
       created again the next file you select the `build` target.
  * **Image/container information**
    - `lsimg`: Lists docker images.
    - `lscont`: Lists docker containers.
    - `lsaddr`: Lists docker container names and network addresses.
  * **Shell utilities**
    - `zsh-%`: Starts a login zsh on the container specified by `%`
      using `docker exec`. The specification may be either the
      container id or the container name.
    - `ssh-%`: Connects as root to the container specified by `%`
      using ssh. The specification should be a container name.
    - `clean-ssh`: Removes the host keys of all container with an
      active network configuration from your ssh `authorized_keys`
      file.
      This is useful when you modify the bootstrapping scripts and
      then rebuild the image. Note that this affects *any* and *all*
      containers with an active network configuration.

### Makefile configuration variables
As we have mentioned above, `Makefile.vars` and `Makefile.local.vars`
are the entry points for configuring PANDAcap. Variables defined
there can be passed down and used by other parts of PANDAcap.
This happens through the use of [j2cli][j2cli] to parse the Makefile
variables and render them into [Jinja2 templates][jinja2] templates.

[at-vm-url]: https://academictorrents.com/details/39df3904460e909e175434cbd87764b8c487891d
[baseimage]: https://github.com/phusion/baseimage-docker
[docker]: https://www.docker.com/
[eurosec20-www]: https://www.concordia-h2020.eu/eurosec-2020/
[eurosec20-doi]: https://doi.org/10.1145/3380786.3391396
[eurosec20-preprint]: https://www.google.com/
[j2cli]: https://github.com/m000/j2cli
[jinja2]: https://jinja.palletsprojects.com/
[panda-dockerfile]: https://github.com/panda-re/panda/blob/master/panda/docker
[panda]: https://github.com/panda-re/panda/
[recctrl]: https://github.com/

