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

# Copies scripts to run directory.
define copy_scripts
$(foreach f,$(wildcard scripts/$(1)_*.sh),$(CP) $(f) $(2)/scripts/$(patsubst $(1)_%,%,$(notdir $(f)));)
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

%/id_ed25519:
	@[ -d $(dir $(@)) ] || mkdir -p $(dir $(@))
	ssh-keygen -q -t ed25519 -P "" -C "$(*)" -f $(basename $(@))

%/docker: bootstrap.sh bootstrap.env %/id_ed25519
	@[ -d $(@) ] || mkdir -p $(@)/files $(@)/scripts
	$(CP) bootstrap.sh bootstrap.env $(@)
	$(CP) $(wildcard $(dir $(@))/id_*) $(@)/files
	$(call copy_scripts,$(notdir $(@)),$(@))

%/vm: bootstrap.sh bootstrap.env %/id_ed25519
	@[ -d $(@) ] || mkdir -p $(@)/files $(@)/scripts
	$(CP) bootstrap.sh bootstrap.env $(@)
	$(CP) $(wildcard $(dir $(@))/id_*) $(@)/files
	$(call copy_scripts,$(notdir $(@)),$(@))

#####################################################################

run.%: run.%/docker run.%/vm	##-	create a new run directory
	@printf "Created \"%s\".\n" $(@)

clean-run:	##- cleanup generated run directories
	rm -rf $(wildcard run.*)

help:		##- show this help
	@sed -e '/#\{2\}-/!d; s/\\$$//; s/:[^#\t]*/:/; s/#\{2\}- *//' $(MAKEFILE_LIST)

