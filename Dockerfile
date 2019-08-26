# Use a fixed release for more reproducible results.
# List of releases: https://github.com/phusion/baseimage-docker/releases
# FROM phusion/baseimage:0.11
FROM phusion/baseimage:master
LABEL maintainer="Manolis Stamatogiannakis <manolis.stamatogiannakis@vu.nl>"
LABEL description="Blah."
LABEL version="0.1"
WORKDIR /

# Add user.
#RUN useradd -ms /bin/bash newuser

# Dpkg::Options::="--force-confold" keeps existing configurations
# intact when upgrading.
RUN apt-get update \
	&& apt-get -y upgrade -o Dpkg::Options::="--force-confold" \
	&& apt-get -y install zsh asciinema tmux \
		libcapstone3 libdwarf1 libprotobuf10 libprotobuf-c1 \
		$(apt-cache depends qemu-system-x86 | awk '/Depends:/{ print $2 }') \
	&& apt-get -y install libcapstone3 libdwarf1 libprotobuf10 libprotobuf-c1 \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/* /var/tmp/*

# Setup our stuff.
ADD resources/panda.tar /opt/panda/
VOLUME ["/opt/panda/share/qcow/", "/opt/panda/share/rr/"]
ENV PATH /opt/panda/bin:$PATH
WORKDIR /opt/panda/share/rr

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

