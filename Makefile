# Makefile for automating some docker related stuff.

-include Makefile.vars

# PANDA image name.
PANDA_IMG ?= prov2r

# PANDA installation location. Used to create the tarball we copy to the image.
PANDA_INSTALL ?= /opt/panda

# Files to check to determine whether we need to create a new tarball.
PANDA_INSTALL_CHECK = $(wildcard $(PANDA_INSTALL)/bin/*)

# Stub file used to determine whether the docker image needs to be updated.
DOCKER_STUB = .docker_stub

define containers_addr
$(shell docker network inspect bridge -f "{{ range .Containers }}{{ .IPv4Address }} {{ end }}")
endef

define containers_name_addr
$(shell docker network inspect bridge -f "{{ range .Containers }}{{ .Name }}:{{ .IPv4Address }} {{ end }}")
endef

.PHONY: all build clean ssh_keyclean lscont lsimg lsaddr

all: build

resources/panda.tar: $(PANDA_INSTALL_CHECK) 
	tar -cvf $(@) -C $(PANDA_INSTALL) .

$(DOCKER_STUB): Dockerfile resources/panda.tar resources/bootstrap.tar
	@printf "Changed files: %s\n" "$(?)"
	docker build . -t $(PANDA_IMG)
	touch $(@)

build: $(DOCKER_STUB)

shell-%:
	@docker exec -t -i $(*) zsh -l

ssh-%:
	@ssh root@$$(echo $(containers_name_addr) | grep ^$(*) | awk -F'[/:]' '{print $$2}')

run:
	docker run -i \
		--mount 'type=bind,src=/home/mstamat/spammer,dst=/opt/panda/share/rr,readonly' \
		-t $(PANDA_IMG)

lsimg:
	@docker image list

lscont:
	@docker container list

lsaddr:
	@echo $(containers_name_addr) | sed -E 's/ /\n/g' | \
		awk -F'[/:]' '{printf("%-20s %s\n", $$1, $$2);}'

ssh_keyclean:
	$(foreach ip,$(call containers_addr),__a="$(ip)"; ssh-keygen -R $${__a%%/*};)

clean:
	docker container prune -f
	docker image prune -f


