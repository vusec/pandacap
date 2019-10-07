#####################################################################
# Makefile for preparing files for bootstrapping the docker image.  #
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

# Files to check to determine whether we need to create a new PANDA tarball.
PANDA_PATH_CHECK = $(wildcard $(PANDA_PATH)/bin/*)

# Files used to bootstrap the docker image.
DOCKER_BOOTSTRAP_GEN = $(basename $(wildcard files/*.j2))
DOCKER_BOOTSTRAP_FILES = $(wildcard scripts/* files/*) $(DOCKER_BOOTSTRAP_GEN) bootstrap.sh bootstrap.env

# Targets for all/clean.
TARGETS = panda.tar bootstrap.tar

#####################################################################

.PHONY: all clean

all: $(TARGETS)

# We need one rule per intermediate file-type that is rendered from a template.
# make will not consider match-all (%) rules for intermediate files.
# See: https://www.gnu.org/software/make/manual/make.html#Chained-Rules
%.env: %.env.j2 $(MAKEFILE_VARS)
	$(PYRUN) j2 $(<) -f env $(MAKEFILE_VARS) -o $(@)

%.sh: %.sh.j2 $(MAKEFILE_VARS)
	$(PYRUN) j2 $(<) -f env $(MAKEFILE_VARS) -o $(@)
	chmod 755 $(@)

bootstrap.tar: $(DOCKER_BOOTSTRAP_FILES)
	tar -cvhf $(@) -C $(@D) --exclude '*.j2' $(subst $(@D)/,,$(^))

panda.tar: $(PANDA_PATH_CHECK)
	tar -cvf $(@) -C $(PANDA_PATH) .

clean:
	rm -f $(TARGETS) $(DOCKER_BOOTSTRAP_GEN) bootstrap.env
