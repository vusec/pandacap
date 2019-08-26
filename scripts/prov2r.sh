#!/usr/bin/env zsh

#####################################################################
# default options and argument parsing                              #
#####################################################################
DEBUG=1
scriptname=$(basename $0)
scriptdir=$(dirname $0)
zparsespec+=${zparsespec:+ }"m: t: mem: disk: net: display: os: rr: panda: plog: sdb:"
zparsespec+=${zparsespec:+ }"docker docker_image:=docker_opts docker_rr:=docker_opts docker_rtconfig:=docker_opts"
typeset -A opts=(
	# common options
	-m			"replay"
	-t			"i386"
	-mem		"512"

	# live options (rec/maint)
	-disk		"$HOME/spammer/panda-qcow/ubuntu16-planb.qcow2"
	-net        "-device e1000,netdev=unet0 -netdev user,id=unet0,hostfwd=tcp::10022-:22"
	-display	":78"
	-sdb        ""

	# replay options
	-os			"linux-32-ubuntu:4.4.0-130-generic"
	-rr			"ubuntu16-test"
	-panda		""
	-plog		"my.plog"
)
typeset -A docker_opts=(
	-docker_image       "prov2r"
	-docker_rr          ""
    -docker_rtconfig    ""
)
zparseopts -D -E -K -A opts ${=zparsespec}
#####################################################################

#####################################################################
# helpers                                                           #
#####################################################################
msg() {
	local fmt=$1
	shift
	printf "%s: $fmt\n" $scriptname $* >&2
}

dump_opts() {
	msg "opts"
	for k in "${(@k)opts}"; do
		echo "\t$k -> $opts[$k]" >&2
	done
	msg "docker opts"
	for k in "${(@k)docker_opts}"; do
		echo "\t$k -> $docker_opts[$k]" >&2
	done
	echo "" >&2
}

p_rel() {
	realpath --relative-base=$PWD $1
}

p_abs() {
	readlink -f $1
}

p_test() {
	if [ ! -$2 $1 ]; then
		msg 'no %s found on "%s"' $3 $1
		exit 1
	fi
}

create_disk() {
	if (( $# > 1 )); then
		qemu-img create -f qcow2 -o compat=0.10 $1 -o backing_file=$2
	else
		qemu-img create -f qcow2 -o compat=0.10 $1
	fi
}

create_sdb() {
	if (( $# != 2 )); then
		msg 'Need exactly 2 arguments to create sdb image.'
		return 1
	fi
	if [ ! -d $2 ]; then
		msg 'Need a directory to create an sdb image.'
		return 1
	fi

	# create tarball
	local tarball=$(mktemp /tmp/sdb.XXXXXX.tar.gz)
	tar -zcf $tarball -C $2 .

	# create filesystem
	local img_size=10
	local mkfs="mkfs.ext4 -O ^has_journal"
	dd if=/dev/zero of=$1 bs=1M count=0 seek=$img_size
	${=mkfs} $1

	# copy tarball to filesystem using debugfs - no root required
	debugfs -wR "write $tarball contents.tar.gz" $1
}
#####################################################################

#docker run -i --name lolos --mount 'type=bind,src=/home/mstamat/spammer,dst=/opt/panda/share/rr,readonly' --mount 'type=bind,src=/home/mstamat/spammer/panda-qcow/ubuntu16-planb.qcow2,dst=/opt/panda/share/qcow/ubuntu16-planb.qcow2,readonly' -t prov2r
#docker exec -i -t prov2r /bin/bash
if (( DEBUG )); then
	dump_opts
fi

#####################################################################
# derived options                                                   #
#####################################################################
panda_mem=${opts[-mem]}
panda_disk=$(p_rel ${opts[-disk]})
panda_rr=$(p_rel ${opts[-rr]})
panda_plugins=${opts[-panda]:+-panda }${opts[-panda]}
panda_bin="panda-system-${opts[-t]}"
panda=$(which $panda_bin)

# find PANDA binary
if [ $? = 0 ]; then
	msg "PANDA binary found in shell path"
	panda=$(p_abs $panda)
	panda_path=$(p_abs "$(dirname $panda)/..")
else
	msg "PANDA binary not found in shell path"
	panda=""
	for d in "$PWD"/panda*; do
		dtarget="${d}/${opts[-t]}-softmmu"
		[ -x "${dtarget}/${panda_bin}" ] || continue
		msg "PANDA binary found in local path"
		panda_path="./$(p_rel ${dtarget})"
		panda="./$(p_rel "${dtarget}/${panda_bin}")"
		break
	done
fi
p_test $panda x "executable for PANDA"

# ??? do we need this ???
#export LD_LIBRARY_PATH=$(p_abs "${panda_path}/panda_plugins")
#####################################################################


#####################################################################
# mode specific options, sanity checks and command construction     #
#####################################################################
case ${opts[-m]} in
	record|rec)
		p_test $panda_disk f "disk image"
		#create_disk $panda_disk
		# test for disk image, create derived image if needed
		#qemu-img create -f qcow2 -o compat=0.10 aderived.qcow2 -o backing_file=$panda_disk
		export DISPLAY=${opts[-display]}
		cmd="$panda -m $panda_mem -hda $panda_disk -usbdevice disk:format=raw:img.raw -monitor stdio ${opts[-net]}"
		;;
	maintenance|maint)
		p_test $panda_disk f "disk image"
		#create_disk $panda_disk
		# test for disk image, create derived image if needed
		#qemu-img create -f qcow2 -o compat=0.10 aderived.qcow2 -o backing_file=$panda_disk
		if (( $panda_mem < 4096 )); then
			panda_mem=4096
		fi
		export DISPLAY=${opts[-display]}
		cmd="$panda -m $panda_mem -hda $panda_disk -monitor stdio ${opts[-net]} -enable-kvm"
		;;
	replay|repl)
		p_test "${panda_rr}-rr-snp" f "trace memory snapshot"
		p_test "${panda_rr}-rr-nondet.log" f "trace nondet log"
		cmd="$panda -m $panda_mem -display none $panda_plugins -os ${opts[-os]} -pandalog ${opts[-plog]} -replay $panda_rr $@"
		;;
	test)
		msg 'Mode "%s" not implemented.' ${opts[-m]}
		exit 1
		#cmd=$(printf "%q " $panda -m $panda_mem -hda $panda_disk -display none -replay $panda_rr -os ${opts[-os]} \
			#-panda osi \
			#-panda syscalls2:profile=linux_x86 \
			#-panda file_taint:filename=index.html \
			#-panda file_taint_sink:sink=index.html $@)
			#-panda file_taint:filename=hello.txt \
			#-panda file_taint_sink:sink=hellov.txt+lol.txt \
		;;
	*)
		msg 'Mode "%s" is invalid.' ${opts[-m]}
		exit 1
		;;
esac
#####################################################################


#####################################################################
# run                                                               #
#####################################################################
msg "
	mode           \t%s
	PANDA          \t%s
	VM-memory      \t%dMB
	VM-disk        \t%s
	PANDA-replay   \t%s
	PANDA-plugins  \t%s
	PANDA-os       \t%s
	LD_LIBRARY_PATH\t%s
	DISPLAY        \t%s
"	${opts[-m]} $panda $panda_mem $(basename $panda_disk) \
	$panda_rr ${opts[-panda]:-"N/A"} ${opts[-os]} \
	${LD_LIBRARY_PATH:="N/A"} ${DISPLAY:-"N/A"}
msg "%s " $cmd
${=cmd}
#####################################################################

# vim: set noet ts=4 sts=4 sw=4 ai ft=sh :# 
