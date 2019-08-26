#!/bin/bash

#####################################################################
# configuration defaults                                            #
#####################################################################
# location of the PADA source tree
PANDA_SRC=${PANDA_SRC:-"$HOME/spammer/panda"}

# location of additional plugins that should be built alongside PANDA
PANDA_PLUGINS_EXTRA=${PANDA_PLUGINS_EXTRA:-"$HOME/spammer/panda-plugins"}

# directory to use for building PANDA
PANDA_BUILD=${PANDA_BUILD:-"$HOME/spammer/panda-build"}

# final installation location for PANDA binaries
PANDA_INSTALL=${PANDA_INSTALL:-"/opt/panda"}

# location of the docker build root
PANDA_DOCKER_BUILD=${PANDA_DOCKER_BUILD:-"/home/mstamat/git/prov2r_dataset"}
#####################################################################


#####################################################################
# sanity checks                                                     #
#####################################################################
case "$PANDA_INSTALL" in
    /*)
        ;;
    *)
        printf 'Aborting. PANDA_INSTALL path "%s" is not absolute.\n' "$PANDA_INSTALL" >&2
        exit 1
        ;;
esac
#####################################################################


#####################################################################
# functions                                                         #
#####################################################################
cleanup() {
    rm -rf "$PANDA_BUILD"
}

configure() {
    mkdir -p "$PANDA_BUILD"
    cd "$PANDA_BUILD"
    "$PANDA_SRC"/configure \
        --prefix="$PANDA_INSTALL" \
        --target-list=x86_64-softmmu,i386-softmmu,arm-softmmu,ppc-softmmu \
        --cc=gcc-5 --cxx=g++-5 \
        --enable-llvm --with-llvm=/usr/lib/llvm-3.3 \
        --python=python2 \
        --disable-vhost-net \
        --extra-cflags=-DXC_WANT_COMPAT_DEVICEMODEL_API \
        --extra-cflags=-DPANDA_LOG_LEVEL=PANDA_LOG_DEBUG \
        --extra-cflags=-DOSI_MAX_PROC=256 \
        --extra-cflags=-g
}

build() {
    cd "$PANDA_BUILD"
    make -j $(nproc)
}

install() {
    if [ ! -d "$PANDA_INSTALL" ]; then
        printf 'please create directory "%s"\n' "$PANDA_INSTALL" >&2
        return 1
    fi
    if [ -d "$PANDA_INSTALL" -a ! -w "$PANDA_INSTALL" ]; then
        printf 'please make directory "%s" writeable\n' "$PANDA_INSTALL" >&2
        return 1
    fi

    # clean install directory
    find "$PANDA_INSTALL" -depth -mindepth 1 -delete

    # install PANDA
    cd "$PANDA_BUILD"
    make install

    # install support scripts
    cd -
    cp -v pandacap.py "$PANDA_INSTALL"/bin/
}

docker_image() {
    tar -cvf "$PANDA_DOCKER_BUILD"/resources/panda.tar -C "$PANDA_INSTALL" .
    cd "$PANDA_DOCKER_BUILD"
    docker build -t pandacap .
}

run() {
    while [ $# != 0 ]; do
        case "$1" in
            cleanup|configure|build|install|clean_install|docker_image)
                "$1"
            ;;
            *)
                printf 'skipping unknow action "%s"\n' "$1" >&2
            ;;
        esac
        shift
    done
}
#####################################################################


if [ $# = 0 ]; then
    run cleanup
    run configure
    run build
else
    run "$@"
fi
