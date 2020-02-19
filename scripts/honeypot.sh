#!/bin/zsh
#####################################################################
# Script for launching a single PANDAcap honeypot from supervisord. #
#####################################################################

### Configuration variables #########################################
# Debug mode.
if [ "$DEBUG" = 1 ]; then
  if [ -z "$i" ]; then
    SUPERVISOR_PROCESS_NAME=$(printf "pandahoney_%02d" "$i")
  else
    SUPERVISOR_PROCESS_NAME="pandahoney_00"
  fi
  SUPERVISOR_GROUP_NAME="pandahoney"
elif [ -z "$SUPERVISOR_PROCESS_NAME" -o -z "$SUPERVISOR_GROUP_NAME" ]; then
  printf "Please use DEBUG=1 when invoking the script directly.\n" >&2
  exit 20
fi

# Influential directories.
SCRIPTS_DIR=$(readlink -f $(dirname "$0"))
BOOTSTRAP_MAKEDIR=$(readlink -f "$SCRIPTS_DIR"/../bootstrap.honey2/run)
RR_ROOT="/mnt/data/pandahoney/rr"
if [ ! -d "$RR_ROOT" ]; then
  printf "RR_ROOT directory does not exist: %s" "$RR_ROOT" >&2
  exit 21
fi
BS_ROOT="/mnt/data/pandahoney/bs"
if [ ! -d "$BS_ROOT" ]; then
  printf "BS_ROOT directory does not exist: %s" "$BS_ROOT" >&2
  exit 22
fi

# QEMU image info.
VM_IMAGE_DIR="/home/mstamat/spammer/panda-qcow"
VM_IMAGE="ubuntu16-planb.qcow2"

# File used to keep count of runs.
RUN_COUNTER="$RR_ROOT"/"$SUPERVISOR_GROUP_NAME".count

# Format for run id.
RUNID_FMT="$SUPERVISOR_GROUP_NAME.%04d"

# Process to port mappings and offset for unmapped ports.
declare -A PROCESS2PORT
PROCESS2PORT=( 0 22 1 2200 2 2222 )
UNMAPPED_OFFSET=47000
#####################################################################

### Helper functions ################################################
get_port() {
    local p=$PROCESS2PORT[$1]
    if [ -z $p ]; then
        p=$(( $UNMAPPED_OFFSET + $1 ))
    fi
    echo $p
}

get_next_run() {
(
  flock -w 10 9 || exit 1
  if [ ! -f "$RUN_COUNTER" ]; then
    rc=0
  else
    rc=$(( $(<"$RUN_COUNTER") + 1 ))
  fi
  echo $rc > "$RUN_COUNTER"
  echo $rc
) 9>"$RUN_COUNTER".lck
}

make_bs() {
(
  flock -w 10 8 || exit 1
  make -C "$BOOTSTRAP_MAKEDIR" "$BS_ROOT"/"$1".rund
) 8>"$BS_ROOT"/make.lck
}
#####################################################################

### Run #############################################################
set -e

# Variables needed to run.
runsn=$(get_next_run)
runid=$(printf "$RUNID_FMT" $runsn)
spn=$(( ${SUPERVISOR_PROCESS_NAME##*_} ))
sshfwd=$(get_port $spn)

# Prepare directories.
mkdir -vp "$BS_ROOT"
mkdir -vp "$RR_ROOT"/"$runid"
make_bs "$runid"

# Dump runid, ssh port mapping.
printf "%s:%s:%s\n" "$runid" "$SUPERVISOR_PROCESS_NAME" "$sshfwd" > "$RR_ROOT"/"$runid"/sshfwd.txt

# Dump command.
cat > "$RR_ROOT"/"$runid"/cmd.txt <<EOF
"$SCRIPTS_DIR"/pandacap.py -vvv \
  --run-id="$runid" \
  -d "$VM_IMAGE_DIR"/"$VM_IMAGE" \
  --port-fwd=ssh:10000 --port-fwd=sftp:10001 \
  --docker-image=pandacap --docker-port-fwd="$sshfwd:10000:*:tcp" \
  -M rr:"$RR_ROOT"/"$runid" \
  -M qcow:"$VM_IMAGE_DIR" \
  -M bootstrap:"$BS_ROOT"/"$runid"/docker \
  rec --usbdisk="$BS_ROOT"/"$runid"/vm --panda="recctrl:session_rec=y,nrec=1,timeout=1800"
EOF

# Run command.
. "$RR_ROOT"/"$runid"/cmd.txt

# Wait a bit before supervisord relaunches VM.
sleep 5
exit 0

