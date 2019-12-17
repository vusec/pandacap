# Use a fixed release for more reproducible results.
# List of releases: https://github.com/phusion/baseimage-docker/releases
# FROM phusion/baseimage:0.11
FROM phusion/baseimage:master

# Configurable options used during image creation.
ARG image_maintainer="Manolis Stamatogiannakis <manolis.stamatogiannakis@vu.nl>"
ARG image_description="PANDA docker image"
ARG image_version="0.5"
ARG image_extra_packages=""
ARG docker_bootstrap="."
ARG panda_path="/opt/panda"

LABEL maintainer=${image_maintainer} \
      description=${image_description} \
      version=${image_version}

# Step 1 - update and install runtime dependencies
# Dpkg::Options::="--force-confold" retains existing configs.
# We don't include update + upgrade in the bootstrapping scripts
# because we only want to occassionally perform them.
RUN apt-get update \
    && apt-get -y upgrade -o Dpkg::Options::="--force-confold" \
    && apt-get -y install ${image_extra_packages} \
        libcapstone3 libdwarf1 libprotobuf10 libprotobuf-c1 \
        $(apt-cache depends qemu-system-x86 | awk '/Depends:/{ print $2 }') \
    && apt-get -y install libcapstone3 libdwarf1 libprotobuf10 libprotobuf-c1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Step 2 - bootstrap container
ADD ${docker_bootstrap}/bootstrap.tar /tmp/bootstrap/
RUN /tmp/bootstrap/bootstrap.sh

# Step 3 - copy PANDA in the container
ADD ${docker_bootstrap}/panda.tar ${panda_path}

# Step 4 - set container environment
ENV PATH ${panda_path}/bin:$PATH
ENV PANDA_PATH ${panda_path}
WORKDIR "${panda_path}/share/rr"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

