#####################################################################
# Makefile for runtime bootstrapping of docker container and VM.    #
#####################################################################

# Makefile directory.
MAKEFILE_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# Project top-level, relative to MAKEFILE_DIR.
PROJECT_ROOT = ../..

# Variables that influence the build process.
include $(PROJECT_ROOT)/Makefile.vars

# Python virtualenv wrapper. Used for running j2.
PYRUN = $(PROJECT_ROOT)/scripts/pyrun.sh

# All makefile variables - determined at runtime to use as dependencies.
MAKEFILE_VARS = $(wildcard $(PROJECT_ROOT)/Makefile.vars $(PROJECT_ROOT)/Makefile.local.vars)

# Copy command.
CP = cp -vf

#####################################################################

# Copies files from list starting with fpref to target, removing rpref.
# $1->list of files, $2->target, $3->fpref, $4->rpref
define copy_files
for s in $(filter $(3)%,$(1)); do \
	t=$${s##*/$(4)}; \
	$(CP) "$$s" $(2)/"$$t"; \
done
endef

# Regex replace with sed.
define resub
$(shell echo "$(1)" | sed "$(2)")
endef
#####################################################################

.PHONY: all help clean-run

.PRECIOUS: %/docker %/vm

all: help

# We need one rule per intermediate file-type that is rendered from a template.
# make will not consider match-all (%) rules for intermediate files.
# See: https://www.gnu.org/software/make/manual/make.html#Chained-Rules
%.env: %.env.j2 $(MAKEFILE_VARS)
	$(PYRUN) j2 $(<) -f env $(MAKEFILE_VARS) -o $(@)

%.sh: %.sh.j2 $(MAKEFILE_VARS)
	$(PYRUN) j2 $(<) -f env $(MAKEFILE_VARS) -o $(@)
	chmod 755 $(@)

%/id_ed25519:
	@[ -d $(dir $(@)) ] || mkdir -p $(dir $(@))
	ssh-keygen -q -t ed25519 -P "" -C "$(call resub,$(*),"s/[^0-9]//g")" -f $(basename $(@))

%/id_ed25519.pub: %/id_ed25519
	true

%/docker: bootstrap.sh bootstrap.env %/id_ed25519 %/id_ed25519.pub $(wildcard scripts/docker_*) files/recvmssh.sh
	@[ -d $(@) ] || mkdir -p $(@)/files $(@)/scripts
	@$(CP) bootstrap.sh bootstrap.env $(@)
	@$(call copy_files,$(^),$(@)/scripts,scripts/docker_,docker_)
	@$(call copy_files,$(^),$(@)/files,files/,)
	@$(call copy_files,$(^),$(@)/files,$(*)/id_,)

%/vm: bootstrap.sh bootstrap.env %/id_ed25519 %/id_ed25519.pub $(wildcard scripts/vm_*) files/recctrlu.sh
	@[ -d $(@) ] || mkdir -p $(@)/files $(@)/scripts
	@$(CP) bootstrap.sh bootstrap.env $(@)
	@$(call copy_files,$(^),$(@)/scripts,scripts/vm_,vm_)
	@$(call copy_files,$(^),$(@)/files,files/,)
	@$(call copy_files,$(^),$(@)/files,$(*)/id_,)

#####################################################################

run.%: run.%/docker run.%/vm	##-	create a new run directory
	@printf "Created \"%s\".\n" $(@)

%.rund: %/docker %/vm	##-	create a new run directory using absolute path
	@printf "Created \"%s\".\n" $(@)

clean-run:	##- cleanup generated run directories
	rm -rf $(wildcard run.*)

help:		##- show this help
	@sed -e '/#\{2\}-/!d; s/\\$$//; s/:[^#\t]*/:/; s/#\{2\}- *//' $(MAKEFILE_LIST)

