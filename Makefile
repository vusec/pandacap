#####################################################################
# Makefile for automating some docker related stuff.                #
#####################################################################

# Makefile directory.
MAKEFILE_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# Project top-level, relative to MAKEFILE_DIR.
PROJECT_ROOT = .

# Variables that influence the build process.
include $(PROJECT_ROOT)/Makefile.vars

# Python virtualenv wrapper. Used for running j2.
PYRUN = $(PROJECT_ROOT)/scripts/pyrun.sh

# All makefile variables - determined at runtime to use as dependencies.
MAKEFILE_VARS = $(wildcard $(PROJECT_ROOT)/Makefile.vars $(PROJECT_ROOT)/Makefile.local.vars)

# Copy command.
CP = cp -vf

# Bootstrap files.
BOOTSTRAP_FILES=$(wildcard resources/bootstrap-*/*)

# Stub file used to determine whether the docker image needs to be updated.
DOCKER_STUB = $(DOCKER_BOOTSTRAP)/.docker_stub

# Files used for docker image bootstrap.
DOCKER_BOOTSTRAP_FILES=panda.tar bootstrap.tar

# Directory name to use for runtime bootstrapping of containers when testing.
CTEST_BOOTSTRAP ?= run.1

# GNU extension - all commands of a recipe are executed in the same shell.
.ONESHELL:

#####################################################################

# Prints the addresses of available containers.
define containers_addr
$(shell docker network inspect bridge -f "{{ range .Containers }}{{ .IPv4Address }} {{ end }}")
endef

# Prints name:address pairs for the available containers.
define containers_name_addr
$(shell docker network inspect bridge -f "{{ range .Containers }}{{ .Name }}:{{ .IPv4Address }} {{ end }}")
endef

#####################################################################

.PHONY: all help clean-files clean-ssh clean-docker lsaddr lscont lsimg up_docker_bootstrap build

.NOTPARALLEL: all

all: up_docker_bootstrap build

up_docker_bootstrap:
	+make -C $(DOCKER_BOOTSTRAP) $(DOCKER_BOOTSTRAP_FILES)

$(DOCKER_STUB): Dockerfile $(addprefix $(DOCKER_BOOTSTRAP)/,$(DOCKER_BOOTSTRAP_FILES)) $(MAKEFILE_VARS)
	@printf "Changed files: %s\n" "$(?)"
	docker build . -t $(IMAGE_NAME) \
		--build-arg image_maintainer="$(IMAGE_MAINTAINER)" \
		--build-arg image_description="$(IMAGE_DESCRIPTION)" \
		--build-arg image_version="$(IMAGE_VERSION)" \
		--build-arg image_extra_packages="$(IMAGE_EXTRA_PACKAGES)" \
		--build-arg docker_bootstrap="$(DOCKER_BOOTSTRAP)" \
		--build-arg panda_path="$(PANDA_PATH)"
	touch $(@)

$(DOCKER_BOOTSTRAP)/%:
	make -C $(DOCKER_BOOTSTRAP) $(*)

#####################################################################

build: $(DOCKER_STUB)		##- build or refresh the image

sh-%:		##- start a root shell on a running container
	@docker exec -t -u root -i $(*) zsh -l

ush-%:		##- start a root shell on a running container
	@docker exec -t -u $(DOCKER_USER) -i $(*) zsh -l

ssh-%:		##- ssh to a running container as root
	@ssh root@$$(echo $(containers_name_addr) | grep ^$(*) | awk -F'[/:]' '{print $$2}')

ussh-%:		##- ssh to a running container as user
	echo ssh $(DOCKER_USER)@$$(echo $(containers_name_addr) | grep ^$(*) | awk -F'[/:]' '{print $$2}')

ctest-%:	##- start a new container with the specified name using IMAGE_NAME
	export IMAGE_NAME=$(IMAGE_NAME)
	export DOCKER_RUN="$(realpath $(RUNTIME_BOOTSTRAP)/$(CTEST_BOOTSTRAP)/docker)"
	[ -z "$$DOCKER_RUN" ] && export DOCKER_RUN="/dev/null"
	docker run --net=test --name $(*) -h $(*) \
		--mount "type=bind,src=$$DOCKER_RUN,dst=$(PANDA_PATH)/share/bootstrap" \
		-i -t "$$IMAGE_NAME"

ctest:		##- start a new container using IMAGE_NAME
	export IMAGE_NAME=$(IMAGE_NAME)
	export DOCKER_RUN="$(realpath $(RUNTIME_BOOTSTRAP)/$(CTEST_BOOTSTRAP)/docker)"
	[ -z "$$DOCKER_RUN" ] && export DOCKER_RUN="/dev/null"
	docker run --net=test \
		--mount "type=bind,src=$$DOCKER_RUN,dst=$(PANDA_PATH)/share/bootstrap" \
		-i -t "$$IMAGE_NAME"

lsimg:		##- list available docker images
	@docker image list

lscont:		##- list available docker containers
	@docker container list

lsaddr:		##- list IP addresses of available docker containers
	@echo $(containers_name_addr) | sed -E 's/ /\n/g' | \
		awk -F'[/:]' '{printf("%-20s %s\n", $$1, $$2);}'

clean-docker:	##- clean docker containers
	docker container prune -f
	docker image prune -f

clean-ssh:	##- remove entries for existing containers from your ssh known_hosts file
	$(foreach ip,$(call containers_addr),__a="$(ip)"; ssh-keygen -R $${__a%%/*};)

clean-files:	##- clean files generated during the build process
	make -C $(DOCKER_BOOTSTRAP) clean

help:		##- show this help
	@sed -e '/#\{2\}-/!d; s/\\$$//; s/:[^#\t]*/:/; s/#\{2\}- *//' $(MAKEFILE_LIST)
