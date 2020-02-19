#!/usr/bin/env python3

import argparse
import collections
import itertools
import logging
import os
import socket
import subprocess
import sys
import shlex
import shutil
from datetime import datetime
from pathlib import Path

LOGLEVELS = [logging.WARNING, logging.INFO, logging.DEBUG]
LOGFORMAT = '%(levelname)s: %(message)s'
logging.basicConfig(format=LOGFORMAT, level=LOGLEVELS[0])

#: Available PANDA target platforms.
PANDA_TARGETS = ('i386', 'x86_64', 'arm', 'ppc')

#: Formats for appending portions to command line.
CMD_FORMATS = {
    'panda-bin':        'panda-system-{target}',
    'panda':            '-panda {panda}',
    'mem':              '-m {mem:d}',
    'disk':             '-hda {disk}',
    'usbdisk':          '-usbdevice disk:format=raw:{usbdisk}',
    'nic':              '{nic}',
    'net-cfg':          '-netdev user,id=unet0,{net_fwd_list}',
    'net-fwd':          'hostfwd={proto}:{haddr}:{to:d}-:{from:d}',
    'docker-host':      '{docker_image}-{docker_host_unique}',
    'docker-init':      '/sbin/my_init -- /sbin/setuser {docker_user}',
    'docker-no-init':   '/sbin/setuser {docker_user}',
    'docker-opt':       '-i --name {hostname} -h {hostname} {docker_image}',
    'docker-mnt':       '--mount type={type},src={src},dst={dst}',
    'docker-net':       '--net={docker_net}',
    'docker-fwd':       '-p {haddr}:{from:d}:{to:d}/{proto}',
    'ts-fmt':           '%Y%m%d-%H%M%S',
}

#: Shorthands for docker mountpoints.
DOCKER_MNT_ALIAS = {
    'bootstrap':    {'type':'bind', 'dst': '{docker_panda_root}/share/bootstrap'},
    'qcow':         {'type':'bind', 'dst': '{docker_panda_root}/share/qcow'},
    'rr':           {'type':'bind', 'dst': '{docker_panda_root}/share/rr'},
    'x11':          {'type':'bind', 'dst': '/tmp/.X11-unix', 'src': '/tmp/.X11-unix'},
}

#: Shorthands for port forwards.
PORT_FWD_ALIAS = {
    'ssh':    { 'proto': 'tcp', 'scope': '*', 'from': 22 },
    'sftp':   { 'proto': 'tcp', 'scope': '*', 'from': 2222 },
}

def addattr(self, name, value=None):
    """ Adds an attribute to the object.
       Raises an exception if ithe attribute already exists.
    """
    if name in self:
        raise AttributeError("'%s' object already has attribute '%s'" % (
            self.__class__.__name__, name))
    else:
        self.__setattr__(name, value)
argparse.Namespace.addattr = addattr

def split_and_pad(s, sep, nsplit, pad=None):
    """ Splits string s on sep, up to nsplit times.
        Returns the results of the split, pottentially padded with
        additional items, up to a total of nsplit items.
    """
    l = s.split(sep, nsplit)
    return itertools.chain(l, itertools.repeat(None, nsplit+1-len(l)))

def arg_format(n, args={}, formats=CMD_FORMATS, split=True, **kwargs):
    """ Use args to apply formating one of the pre-defined formats.
    """
    if n not in formats:
        return ''

    if isinstance(args, collections.Mapping):
        arg_s = formats[n].format(**args, **kwargs)
    else:
        arg_s = formats[n].format(**vars(args), **kwargs)

    return shlex.split(arg_s) if split else arg_s

def parse_port_fwd(port_fwd_str):
    """ Parses FROM:TO[:SCOPE[:PROTO]] strings to dict.
    """
    # split string and get defaults
    keys = ['from', 'to', 'scope', 'proto']
    fwd = dict(zip(keys, split_and_pad(port_fwd_str, ':', 3)))
    if fwd['from'] in PORT_FWD_ALIAS:
        defaults = PORT_FWD_ALIAS[fwd['from']]
        fwd['from'] = None
    else:
        defaults = {}
    # apply defaults for missing values
    for k, v in fwd.items():
        if v is not None:
            continue
        elif k in defaults:
            fwd[k] = defaults[k]
            continue
        err = "No value for %s in port forward %s." % (k.upper(), port_fwd_str)
        logging.error(err)
        raise ValueError(err)
    # convert numericals and check for right values
    if isinstance(fwd['from'], str):
        fwd['from'] = int(fwd['from'])
    if isinstance(fwd['to'], str):
        fwd['to'] = int(fwd['to'])
    if fwd['scope'] not in ['*', 'l']:
        err = 'Unknown network scope "%s". Assuming "*".' % fwd['scope']
        logging.warning(err)
        fwd['scope'] = 'h'
    if fwd['proto'] not in ['tcp', 'udp']:
        err = 'Unknown network protocol "%s". Assuming "tcp".' % fwd['proto']
        logging.warning(err)
        fwd['proto'] = 'tcp'
    return fwd

def process_common_args(args):
    """ Process QEMU-related arguments.
    """
    cmd = []
    # add hostname to args
    if 'hostname' not in args:
        args.addattr('hostname', socket.gethostname())
    # add qemu arguments
    for arg_name in ['mem', 'disk', 'usbdisk', 'nic', 'panda']:
        if getattr(args, arg_name, None) is None:
            continue
        else:
            cmd.extend(arg_format(arg_name, args))
    # add qemu port forwards
    scope2haddr = {'*': '', 'l': '127.0.0.1'}
    port_fwd = []
    for fwd in args.port_fwd:
        fwd['haddr'] = scope2haddr[fwd['scope']]
        port_fwd.append(arg_format('net-fwd', fwd, split=False))
    if port_fwd:
        cmd.extend(arg_format('net-cfg', net_fwd_list=','.join(port_fwd)))
    # add qemu monitor
    cmd.extend(['-monitor', 'stdio'])
    return cmd

def process_rec_args(args):
    """ Process PANDA record-related arguments.
    """
    cmd = []
    os.environ['DISPLAY'] = args.display

    # create derived disk
    if not args.no_derive:
        derived_disk = qemu_derive_disk(args.disk, args.run_id)
        if derived_disk is None:
            logging.error("Failed to create derived image from %s.", args.disk)
            sys.exit(1)
        args.addattr('base_disk', args.disk)
        args.addattr('derived_disk', derived_disk)
        args.disk = args.derived_disk

    # create usb disk
    usbdisk = qemu_make_usbdisk(args.usbdisk_dir, args.disk.parent, args.run_id, fslabel='bootstrap')
    if args.usbdisk_dir is not None and usbdisk is None:
        logging.error('Failed to create USB disk image from "%s".', args.usbdisk_dir)
        sys.exit(1)
    args.addattr('usbdisk', usbdisk)

    return cmd

def process_repl_args(args):
    """ Process PANDA replay-related arguments.
    """
    assert False, 'Not implemented yet.'
    cmd = []
    cmd.extend(['-display', 'none'])
    return cmd
    # p_test "${panda_rr}-rr-snp" f "trace memory snapshot"
    # p_test "${panda_rr}-rr-nondet.log" f "trace nondet log"
    # -pandalog ${opts[-plog]} -replay $panda_rr

def process_maint_args(args):
    """ Process maintenance-related arguments.
    """
    cmd = []
    os.environ['DISPLAY'] = args.display
    args.mem = max(args.mem, 4096)
    if not args.no_kvm and not args.docker_image:
        cmd.append('-enable-kvm')
    return cmd

def process_docker_args(args):
    """ Process Docker-related arguments.
        This function returns a list of arguments that can be used to start a
        Docker container to run PANDA into. This includes the docker command as
        well as the required mounts and environment variables. It will also
        rewrite any arguments that require rewriting.
    """
    if args.docker_image is None:
        return []
    else:
        cmd = ['docker', 'run']

    # create hostname
    if False:
        # from timestamp
        docker_host_unique = datetime.now().strftime(CMD_FORMATS['ts-fmt'])
    else:
        # from run_id
        docker_host_unique = args.run_id
    hostname = arg_format('docker-host', split=False,
        docker_image=args.docker_image,
        docker_host_unique=docker_host_unique)
    args.addattr('hostname', hostname)

    # initialize docker mount info
    mounts = dict(DOCKER_MNT_ALIAS)
    for tgt, mnt_args in mounts.items():
        if 'src' in mnt_args:
            # resolve default mount source path
            mnt_args['src'] = Path(mnt_args['src']).resolve()
        if 'dst' in mnt_args:
            # expand mount destination path
            mnt_args['dst'] = mnt_args['dst'].format(**vars(args))

    # set mount source paths specified from command line
    dmnts = map(lambda s: s.split(':', 1), args.docker_mount)
    for tgt, src in dmnts:
        if tgt not in mounts:
            logging.warning('Unknown docker mount target "%s".', tgt)
        else:
            mounts[tgt]['src'] = Path(src).resolve()

    # set automatically derived mount source paths
    if 'src' not in mounts['qcow']:
        logging.debug('Deriving source path for mount target "qcow".')
        mounts['qcow']['src'] = Path(args.disk).parent.resolve()

    # rewrite any arguments depending on mount paths
    args.disk = Path(mounts['qcow']['dst']) / args.disk.name
    if args.usbdisk is not None:
        args.usbdisk = Path(mounts['qcow']['dst']) / args.usbdisk.name

    # add mounts to command
    for tgt, mnt_args in mounts.items():
        if 'src' not in mnt_args:
            logging.warning('No source for docker mount target "%s".', tgt)
            continue
        if not mnt_args['src'].exists():
            logging.warning('Source "%s" for docker mount target "%s" does not exist.',
                    mnt_args['src'], tgt)
            continue
        if 'dst' not in mnt_args:
            logging.warning('No destination for docker mount target "%s".', tgt)
            continue
        cmd.extend(arg_format('docker-mnt', mnt_args))

    # add docker network to command
    if args.docker_net is not None:
        cmd.extend(arg_format('docker-net', args))

    # add port forwards to command
    scope2haddr = {'*': '', 'l': '127.0.0.1'}
    for fwd in args.docker_port_fwd:
        fwd['haddr'] = scope2haddr[fwd['scope']]
        cmd_ext = arg_format('docker-fwd', fwd)
        cmd.extend(cmd_ext)

    # add environment to command
    cmd.extend(['-e', 'DISPLAY={DISPLAY}'.format(**os.environ)])

    # add the remaining docker options to the command
    ts = datetime.now().strftime(CMD_FORMATS['ts-fmt'])
    cmd.extend(arg_format('docker-opt', args, ts=ts))

    # run init and set user using the setuser utility
    # see: https://github.com/phusion/baseimage-docker#whats-inside-the-image
    if args.docker_no_init:
        cmd.extend(arg_format('docker-no-init', args))
    else:
        cmd.extend(arg_format('docker-init', args))

    return cmd

def qemu_derive_disk(base_disk, uid, qcow_compat='0.10'):
    """ Use a base qcow image to create a derived image in the same directory.
        The derived image filename is computed using uid.

        This script is meant to be used to launch PANDA either directly or
        inside a Docker container. To keep things simple, we want to always
        create derived images before launching Docker. The most straightforward
        solution to this is to always create the derived images in the same
        directory with the base (backing) image.
        Other options would be complicate things because the derived image
        includes an absolute or relative path to the base image. This path
        may become invalid when running inside Docker, and extra steps are
        required to avoid this.
    """
    cmd_fmt = 'qemu-img create -f qcow2 -o compat={qcow_compat} {derived_disk} -o backing_file={base_disk}'
    error = False

    base_disk = Path(base_disk)
    derived_disk_name = '%s.%s%s' % (base_disk.stem, uid, base_disk.suffix)
    derived_disk = base_disk.with_name(derived_disk_name)
    logging.info('Preparing derived image "%s" using base image "%s".', derived_disk.name, base_disk)

    # sanity checks
    if not base_disk.exists():
        logging.error('Base image "%s" does not exist.', base_disk)
        error = True
    if derived_disk.exists():
        logging.error('Derived image "%s" already exists.', derived_disk)
        error = True
    if os.access(base_disk, os.W_OK):
        logging.warning('Base image "%s" is writeable.', base_disk)

    if error:
        return None

    # create and run command
    shq = lambda p: shlex.quote(str(p))
    cmd_args = {
        'qcow_compat': qcow_compat,
        'base_disk': shlex.quote(base_disk.name),
        'derived_disk': shlex.quote(str(derived_disk)),
    }
    cmd = shlex.split(cmd_fmt.format(**cmd_args))
    logging.debug('Preparing derived image with command: %s', cmd)
    subprocess.call(cmd)
    return derived_disk

def qemu_make_usbdisk(contents_dir, out_dir, uid, fstype='ext3', fssize='32M', fslabel=''):
    """ Creates a new filesystem image from the contents of contents_dir.
    """
    if contents_dir is None:
        return None
    contents_p = Path(contents_dir)
    if not contents_p.is_dir():
        logging.error('Contents directory "%s" is not a directory.', contents_p)
        return None
    out_p = Path(out_dir)
    if not out_p.is_dir():
        logging.error('Output directory "%s" is not a directory.', out_p)
        return None
    image = out_p.joinpath("usbdisk.%s.img" % (uid))

    if fstype in ['ext2', 'ext3', 'ext4']:
        # Explanation of hardcoded options for mke2fs:
        #   -O ^64bit -> turn off 64bit support – not needed for a small fs
        #   -m 2 -> reserve only 2% of blocks for superuser – no services write on this fs
        cmd_fmt = 'mke2fs -L {fslabel} -O ^64bit -m 2 -t {fstype} -d {dir} {image} {fssize}'
        cmd_args = {
            'dir': shlex.quote(str(contents_dir)),
            'image': shlex.quote(str(image)),
            'fslabel': shlex.quote(fslabel),
            'fstype': fstype,
            'fssize': fssize,
            'uid': shlex.quote(uid),
        }
        cmd = shlex.split(cmd_fmt.format(**cmd_args))
        logging.debug('Preparing filesystem image with command: %s', cmd)
        subprocess.call(cmd)
        return image
    else:
        logging.error("%s filesystems are not supported.", fstype)
        return None

def prov2r_parse_args(argv=[]):
    """ Parses a list of command line arguments.
    """
    # helper lambdas
    _k2s = lambda d: ', '.join(d.keys())

    # argument parser, subparsers and groups
    parser = argparse.ArgumentParser(
        description='PANDA wrapper for PROV2R.',
        epilog='See operation mode help for additional arguments.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    # add common options
    parser.add_argument('-v', '--verbose', action='count',
        default=0,
        help='increase verbosity')
    parser.add_argument('--run-id', action='store',
        default=None,
        help='unique(ish) identifier for this run')
    parser.add_argument('-o', '--output-dir', action='store',
        default='.',
        help='all created files should be stored here')
    # qemu options
    qemu_args = parser.add_argument_group('QEMU options')
    qemu_args.add_argument('-m', '--mem', action='store', type=int,
        default=512,
        help='VM memory')
    qemu_args.add_argument('-t', '--target', action='store',
        default='i386', choices=PANDA_TARGETS,
        help='VM target architecture')
    qemu_args.add_argument('-d', '--disk', action='store', type=Path,
        default='./panda-qcow/ubuntu16-planb.qcow2',
        help='VM disk image')
    qemu_args.add_argument('--nic', action='store',
        default='-device e1000,netdev=unet0',
        help='VM network interface configuration')
    qemu_args.add_argument('--port-fwd', action='append',
        default=[], metavar='FROM:TO[:SCOPE[:PROTO]]', type=parse_port_fwd,
        help='forward VM-port FROM to host-port TO '
             '(see README.md for further explanation)')
    qemu_args.add_argument('-D', '--display', action='store',
        default=':78',
        help='VM display output')
    # docker options
    docker_args = parser.add_argument_group('Docker options')
    docker_args.add_argument('--docker-image', action='store',
        default=None, metavar='IMAGE',
        help='run PANDA in an instance of the specified docker image')
    docker_args.add_argument('--docker-no-init', action='store_true',
        help="skip the baseimage-docker initialization")
    docker_args.add_argument('--docker-user', action='store',
        default='panda',
        help='run PANDA as the specified user inside the docker container')
    docker_args.add_argument('--docker-workdir', action='store',
        default='/opt/panda/share',
        help='working dir inside the docker container')
    docker_args.add_argument('--docker-panda-root', action='store',
        default='/opt/panda', metavar='PANDA_ROOT',
        help='location of PANDA in the docker container')
    docker_args.add_argument('--docker-mount', '-M', action='append',
        default=[], metavar='DST:SRC',
        help='specify a docker mount from host directory SRC to one of '
             'the pre-defined DST locations: (%s)' % _k2s(DOCKER_MNT_ALIAS))
    docker_args.add_argument('--docker-net', action='store',
        default=None,
        help='connect the container to the specified docker network')
    docker_args.add_argument('--docker-port-fwd', action='append',
        default=[], metavar='FROM:TO[:SCOPE[:PROTO]]', type=parse_port_fwd,
        help='forward Docker-port FROM to host-port TO '
             '(see README.md for further explanation)')
    # operation modes
    MODES = {
        'rec': {
            'help': 'record mode',
            'args': ['no-derive', 'os', 'panda', 'plog', 'usbdisk-dir'],
            'process_mode_args': process_rec_args,
        },
        'repl': {
            'help': 'replay mode',
            'args': ['os', 'panda', 'plog', 'rr'],
            'process_mode_args': process_repl_args,
        },
        'maint': {
            'help': 'maintenance mode',
            'args': ['no-kvm'],
            'process_mode_args': process_maint_args,
        },
    }
    MODES_ARGS = {
        'no-derive': {'action': 'store_true', 'help': 'disable creation of derived disk image'},
        'no-kvm': {'action': 'store_true', 'help': 'disable KVM acceleration'},
        'os': {'action': 'store', 'help': 'PANDA operating system specifier', 'default': 'linux-32-ubuntu:4.4.0-130-generic'},
        'panda': {'action': 'store', 'help': 'PANDA plugin specifier', 'default': None},
        'plog': {'action': 'store', 'help': 'PANDA log file to use', 'default': 'my.plog'},
        'rr': {'action': 'store', 'help': 'PANDA replay to use', 'default': 'ubuntu16-test'},
        'usbdisk-dir': {'action': 'store', 'type': Path, 'help': 'create a image from this directory and attach it to the VM as a USB disk', 'default': None},
    }
    subparsers = parser.add_subparsers(dest='mode', help='operation mode')
    subparsers.required = True # required argument added in Python 3.7
    for m, mode_opts in MODES.items():
        mode_opts['parser'] = subparsers.add_parser(m, help=mode_opts['help'],
            description='PANDA wrapper for PROV2R — %s' % mode_opts['help'],
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        for o in mode_opts['args']:
            mode_opts['parser'].add_argument('--%s' % (o), **MODES_ARGS[o])

    # parse arguments / reset loglevel / add mode arguments processing function
    args = parser.parse_args(argv)
    logging.getLogger().setLevel(LOGLEVELS[min(args.verbose, len(LOGLEVELS)-1)])
    args.addattr('process_mode_args', MODES[args.mode]['process_mode_args'])

    # return
    logging.debug("Parsed arguments: %s", args)
    return args

def prov2r_make_command(args):
    """ Creates a PANDA command using the specified args namespace.
    """
    # find PANDA binary
    panda_name = arg_format('panda-bin', args, split=False)
    if args.docker_image is not None:
        # running in docker - assume that the binary is in the path
        panda_bin = panda_name
    else:
        # running on host - search for panda
        panda_bin = shutil.which(panda_name)
        if panda_bin is None:
            dirs1 = filter(Path.is_dir, Path('.').glob('*-softmmu'))
            dirs2 = filter(Path.is_dir, Path('.').glob('*/*-softmmu'))
            path_extra = [str(p) for p in itertools.chain(dirs1, dirs2)]
            panda_bin = shutil.which(panda_name, path=':'.join(path_extra))
    if panda_bin is None:
        logging.error('Could not find PANDA binary (%s) in shell path or locally.', panda_name)
        sys.exit(1)
    else:
        logging.info('Using PANDA binary %s.', panda_bin)

    # if not set, use the script pid as unique(ish) identifier
    if args.run_id is None:
        args.run_id = '%05d' % os.getpid()
    else:
        try:
            args.run_id = '%05d' % int(args.run_id)
        except ValueError:
            pass
    logging.debug('Using run-id %s.', args.run_id)

    # create command components
    # the order is important — functions may modify args
    cmd_mode = args.process_mode_args(args)
    cmd_docker = process_docker_args(args)
    cmd_common = process_common_args(args)

    # concatenate command parts and return
    cmd = [*cmd_docker, panda_bin, *cmd_common, *cmd_mode]
    logging.info('Prepared command: %s', cmd)
    return cmd

if __name__ == '__main__':
    args = prov2r_parse_args(sys.argv[1:])
    cmd = prov2r_make_command(args)
    subprocess.call(cmd)

# ??? do we need this ???
# export LD_LIBRARY_PATH=$(p_abs "${panda_path}/panda_plugins")

# vim: set et ts=4 sts=4 sw=4 ai ft=python :#
