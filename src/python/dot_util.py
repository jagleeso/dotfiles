#!/usr/bin/env python
# -*- coding: utf-8 -*-
import cPickle
import cStringIO
import datetime
import distutils.spawn
import errno
import fnmatch
import hashlib
import itertools
import multiprocessing
import os
import re
import socket
import struct
import subprocess
import sys
import time
import traceback
from os.path import join as _j
from socket import error as socket_error

import bencode
import paramiko
import psutil

import dot_config

def yes_or_no(boolean):
    return 'yes' if boolean else 'no'

def sh_run(cmdargs, skip_sudo=False, sudo_passwd=None):
    env = dict(os.environ)
    env['RUN'] = 'yes'
    env['SKIP_SUDO'] = yes_or_no(skip_sudo)
    if sudo_passwd is not None:
        env['SUDO_PASSWD'] = sudo_passwd
    run_cmd([dot_config.COMMON_SH] + cmdargs, stderr=sys.stderr, stdout=sys.stdout,
            env=env)

def run_cmd(cmdline, **kwargs):
    env = kwargs.get('env', dict(os.environ))
    kwargs['env'] = env
    cmdline = ignore_empty(cmdline)
    return check_call(cmdline, **kwargs)

def ignore_empty(xs):
    if type(xs) == str:
        return xs
    return [x for x in xs if x is not None and x != '']

"""
Processes
"""
def fork_process(f, *args, **kwargs):
    # multiprocessing doesn't print stack traces of failed children =(
    def run_process():
        try:
            f(*args, **kwargs)
        except Exception, e:
            exc_buffer = cStringIO.StringIO()
            traceback.print_exc(file=exc_buffer)
            log(exc_buffer.getvalue())
            raise
    thread = multiprocessing.Process(target=run_process)
    return thread

def each_matching_process(regex):
    def _matches(p, regex):
        cmdline = ' '.join(p.cmdline())
        return re.search(regex, cmdline)
    for p in psutil.process_iter():
        if _matches(p, regex):
            yield p

def kill_matching(pattern):
    def _matches(p, regex):
        cmdline = ' '.join(p.cmdline())
        return re.search(regex, cmdline)
    def each_to_kill(pattern):
        for p in each_matching_process(pattern):
            try:
                if _matches(p, r'--kill-matching'):
                    continue
                if p.pid == os.getpid():
                    continue
            except psutil.NoSuchProcess, e:
                continue
            yield p
    procs = list(each_to_kill(pattern))
    # SIGTERM
    for p in procs:
        try:
            log("TERMINATE {0}".format(' '.join(p.cmdline())))
            p.terminate()
        except psutil.NoSuchProcess, e:
            continue
    gone, alive = psutil.wait_procs(procs, timeout=3)
    # SIGKILL
    for p in alive:
        try:
            log("KILL {0}".format(' '.join(p.cmdline())))
            p.kill()
        except psutil.NoSuchProcess, e:
            continue
    # Better be dead...
    gone, alive = psutil.wait_procs(procs, timeout=3)
    for p in alive:
        try:
            log("Failed to KILL {0}".format(' '.join(p.cmdline())))
        except psutil.NoSuchProcess, e:
            continue
    if len(alive) > 0:
        sys.exit(1)

"""
Misc.
"""
def memoize_newer_than_subdirs(func, args, pickle_file, directory):
    """
    A pickle_file is invalid if at least one subdirectory is newer than it.
    """
    pickle_mtime = os.path.getmtime(pickle_file)
    for d in os.listdir(directory):
        d_path = _j(directory, d)
        if not os.path.isdir(d_path) or \
                        os.path.basename(d_path) in [
                    # These change all the time.  Ignore them.
                    '.git',
                    'shadow_library',
                    'paper',
                    'generated',
                ]:
            continue
        if os.path.getmtime(d_path) > pickle_mtime:
            # print "INVALID: {d_path} > {pickle_file}".format(**locals())
            return False
    # Valid
    return True

class PickleMemoize(object):
    """
    @PickleMemoize(get_directory=lambda arg1, directory, arg2, ...: directory)
    def func(arg1, directory, arg2, ...)
        return <BIG-RESULT>

    @PickleMemoize()
    def func(...)
        return <BIG-RESULT>

    Memoizes function results in a cpickle file inside $directory/.$func.$argument_hash.cpickle

    == directory ==
    Current directory by default.

    == valid ==
    Returns true if pickle_file is valid;
    if pickle_file is invalid, it must be recomputed.

    For example, a policy require that mod_time(pickle_file) >= mod_time(directory)

    This is very implementation specific, so the default is always valid.
    """
    def __init__(self,
                 get_directory=lambda *args: os.getcwd(),
                 valid=lambda func, args, pickle_file, directory: True):
        """
        get_directory(*args): return a directory where the pickle file is saved
        """
        # import pdb
        # pdb.set_trace()
        self.get_directory = get_directory
        self.valid = valid

    def _hash_python(self, data_structure):
        sha = hashlib.sha256(bencode.bencode(data_structure)).hexdigest()
        return sha

    def argument_hash(self, args):
        return self._hash_python(args)

    def __call__(self, func, *args):
        # NOTE:
        # - There is a decorator instance for each @Decorator usage
        # - This gets called on each usage, not each func() call.
        dec = self
        def wrapper(*args):
            directory = dec.get_directory(*args)
            path = dec.pickle_path(directory, func, args)
            ret = None
            if not os.path.exists(path) or not self.valid(func, args, path, directory):
                ret = func(*args)
                with open(path, 'w') as f:
                    cPickle.dump(ret, f)
            else:
                with open(path, 'r') as f:
                    ret = cPickle.load(f)
            return ret
        return wrapper

    def pickle_basename(self, func):
        return func.__name__

    def pickle_path(self, directory, func, args):
        basename = self.pickle_basename(func)
        sha = self.argument_hash(args)
        return _j(directory, ".{basename}.{sha}.cpickle".format(**locals()))

@PickleMemoize(get_directory=lambda root_dir, glob_pattern: root_dir, valid=memoize_newer_than_subdirs)
def find_files(root_dir, glob_pattern):
    """
    Find all files matching a glob pattern, recursively walk the root directory.
    """
    matches = []
    for root, dirnames, filenames in os.walk(root_dir):
        for filename in fnmatch.filter(filenames, glob_pattern):
            matches.append(os.path.join(root, filename))
    return matches

# Logging stuff

def ignore_log(msg=None):
    """
    Ignore log statements
    """
    pass

LOG_FILE_HANDLE = None
LOG_VERBOSE = False
def log(msg=""):
    output = msg.rstrip('\n') + "\n"
    if LOG_FILE_HANDLE is not None and not LOG_FILE_HANDLE.closed:
        LOG_FILE_HANDLE.write(output)
        LOG_FILE_HANDLE.flush()
    sys.stdout.write(output)
    sys.stdout.flush()

def log_ssh(user, host, cmdline):
    log("{user}@{host}: $ {cmdline}".format(**locals()))

# Socket stuff

def connect_to_socket(ip, port, max_time_sec=dot_config.MAX_TIME_SEC, sec_between_tries=0.5):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # tries = max_time_sec / sec_between_tries
    # for i in range(tries):
    while True:
        try:
            sock.connect((ip, port))
            return sock
        except socket_error as serr:
            if serr.errno != errno.ECONNREFUSED:
                # Not the error we are looking for, re-raise
                raise serr
            time.sleep(sec_between_tries)
    return None 

def recv_line(s):
    string = cStringIO.StringIO()
    while True:
        ch = s.recv(1, socket.MSG_WAITALL)
        if ch == '\n':
            return string.getvalue()
        string.write(ch)
def recv(s, sz):
    return s.recv(sz, socket.MSG_WAITALL)
def recv_expect(s, expect):
    msg = recv(s, len(expect))
    recvd_expect(msg, expect)
    return msg
def recvd_expect(msg, expect):
    if msg != expect:
        print "ERROR: got \"{msg}\" on socket but expected \"{expect}\"".format(**locals())
        assert msg == expect
def send(s, msg):
    n = s.send(msg)
    if n != len(msg):
        raise RuntimeError("ERROR: failed to send '{msg}'; saw n = {n}".format(**locals()))
        sys.exit(1)

class Message(object):

    MESSAGE_TYPE_SIZE = 1

    def __init__(self, sock, expect_message_type=None):
        self.sock = sock
        self.message_type = None
        self.params = {}
        self.expect_message_type = expect_message_type
        self._parse()

    def _parse(self):
        if self.expect_message_type is not None:
            recv_expect(self.sock, self.expect_message_type)
            self.message_type = dot_config.SYNC_CLOCK_SIGNAL_ACK
        else:
            self.message_type = recv(self.sock, Message.MESSAGE_TYPE_SIZE)
        if self.message_type == dot_config.SYNC_CLOCK_SIGNAL_ACK:
            self._parse_SYNC_CLOCK_SIGNAL_ACK()
            return
        raise NotImplemented("Not sure how to parse message_type = {0}".format(self.message_type))

    def _parse_fmt(self, names, fmt):
        size = struct.calcsize(fmt)
        byts = recv(self.sock, size)
        unpacked = struct.unpack(fmt, byts)
        for name, val in itertools.izip(names, unpacked):
            self.params[name] = val

    def _parse_SYNC_CLOCK_SIGNAL_ACK(self):
        self._parse_fmt(['timestamp'], 'd')

# Benchmark stuff

def timestamp():
    return time.time()

def start_time():
    dt = datetime.datetime.now()
    return dt.strftime("%A, %d. %B %Y %I:%M%p")

# Process stuff

def popen_or_kill(*args, **kwargs):
    """
    Wrapper around Popen that kills the process if we exit for any reason.
    """
    proc = None
    try:
        proc = subprocess.Popen(*args, **kwargs)
        proc.wait()
        if proc.returncode != 0:
            cmdline = None
            if type(args[0]) == list:
                cmdline = ' '.join(args[0])
            else:
                cmdline = args[0]
            raise subprocess.CalledProcessError(proc.returncode, cmdline)
    except Exception:
        if proc is not None:
            _terminate_proc(proc)
        raise

def _terminate_proc(proc):
    if proc.poll() is None:
        proc.terminate()
        time.sleep(1)
    if proc.poll() is None:
        proc.kill()

def _ignore_empty(xs):
    return [x for x in xs if x is not None]

def cmdline_str(shell_cmd):
    cmdline = None
    if type(shell_cmd) == list:
        cmdline = ' '.join([str(x) for x in _ignore_empty(shell_cmd)])
    else:
        assert type(shell_cmd) == str
        cmdline = shell_cmd
    return cmdline

def check_output(shell_cmd, shell=True, env=None, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, 
        ignore_error=False, silent=False, errcode=False):

    cmdline = cmdline_str(shell_cmd)

    def should_write_manually(outstream):
        return isinstance(outstream, cStringIO.StringIO().__class__)

    user_stdout = stdout
    write_out = False
    if should_write_manually(stdout):
        write_out = True
        stdout = subprocess.PIPE

    user_stderr = stderr
    write_err = False
    if should_write_manually(stderr):
        write_err = True
        stderr = subprocess.PIPE

    p = subprocess.Popen(cmdline, shell=True, stdout=stdout, stderr=stderr, env=env)
    try:
        out, err = p.communicate()
        if write_out:
            user_stdout.write(out)
        if write_err:
            user_stderr.write(err)
    except Exception, e:
        _terminate_proc(p)
        raise e
    def _out(stream):
        return stream.rstrip("\n") + "\n"
    outs = []
    if out is not None:
        outs.append(_out(out))
    if err is not None:
        outs.append(_out(err))
    all_output = ''.join(outs)
    if p.returncode != 0 and not ignore_error:
        ret = p.returncode
        log("ERROR: return code was {ret} for: {shell_cmd}".format(**locals()))
        log(all_output)
        raise subprocess.CalledProcessError(ret, shell_cmd)
    if errcode:
        return all_output, p.returncode
    return all_output

def check_call(cmdline, **kwargs):
    def flush_handle(name):
        if name in kwargs and type(kwargs[name]) == file:
            kwargs[name].flush()
    if not kwargs.get('silent', False):
        log(cmdline_str(cmdline))
    flush_handle('stdout')
    flush_handle('stderr')
    return check_output(cmdline, **kwargs)

# ssh wrappers around paramiko ssh library

class Ssh(object):
    def __init__(self, ip, user, password):
        log("ssh login: ip={0}, user={1}, pass={2}".format(ip, user, password))
        conn = paramiko.SSHClient()
        conn.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        conn.connect(ip, username=user, password=password)
        chan = conn.get_transport().open_session()
        try:
            chan.exec_command('ls')
            chan.close()
        except socket.error as e:
            log("ERROR: failed to ssh into {ip}.".format(**locals()))
            sys.exit(1)
        # Fails on zsh
        # ssh_exec(conn, 'set -o pipefail')
        self.conn = conn
        self.shell = self.ssh_exec("echo $SHELL", silent=True)

    def pipe_status(self, pipe_idx):
        # Hard to get this to work since we can only run one command with paramiko...sigh.
        # http://unix.stackexchange.com/questions/14270/get-exit-status-of-process-thats-piped-to-another
        # if re.search(r'zsh', self.shell):
        # elif re.search(r'bash', self.shell):
        # else:
        #     raise RuntimeError("Unsupported shell")
        raise NotImplemented

    def ssh_exec(self, cmdline, ignore_error=False, err_pattern=None, silent=False):
        real_cmdline = '; '.join([
            "export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin",
            cmdline,
        ])
        if not silent:
            log_ssh(
                user=self.conn.get_transport().get_username(), 
                host=self.conn.get_transport().sock.getpeername()[0],  
                cmdline=cmdline)
        stdin, stdout, stderr = self.conn.exec_command(real_cmdline)
        try:
            ret = stdout.channel.recv_exit_status()
            all_output = ''.join(stdout) + ''.join(stderr)
            if err_pattern is not None:
                for line in all_output.split("\n"):
                    if re.search(err_pattern, line):
                        log("ERROR: output matched error pattern for ssh command on other host: {cmdline}".format(**locals()))
                        log(all_output)
                        sys.exit(1)
            if ret != 0 and not ignore_error:
                log("ERROR: return code was {ret} for ssh command on other host: {cmdline}".format(**locals()))
                log(all_output)
                sys.exit(1)
            return all_output
        finally:
            stdin.close()
            stdout.close()
            stderr.close()

def remove_sudo_prompt(out):
    return re.sub(r'\[sudo\] password for [^:]+: ', '', out)
def proc_output_value(output, default=None):
    output = remove_sudo_prompt(output).rstrip("\n")
    if output == '':
        return default
    return output
def _str_as_number(string, default=None):
    try:
        val = int(string)
        return val
    except ValueError:
        pass
    try:
        val = float(string)
        return val
    except ValueError:
        pass
    return default
def proc_output_number(output, default=None):
    val = proc_output_value(output, default=default)
    val = _str_as_number(val, default=default)
    return val
def proc_output_as_list(output, default=[]):
    string = proc_output_value(output)
    if string is None:
        return default
    return [x for x in re.split(r'\n', string) if x.lower() not in ['']]

def remove_newlines(string):
    return string.translate(None, "\n")

# Directory/file utils

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def which(path):
    return distutils.spawn.find_executable(path)

def program_from_cmdline(cmdline):
    return re.split(r'\s+', cmdline.lstrip(' '))[0]

"""
Runners can run a shell command, and return the stdout + stderr, and fail on non-zero exit status.
Helps us reuse shell code for local vs remote over ssh.
"""
class RemoteSshPassRunner(object):
    def __init__(self, user, password, ip, sudo=False):
        self.user = user
        self.password = password
        self.ip = ip
        self.sudo = sudo

    def sshpass_cmdline(self, cmdline):
        password = self.password
        ip = self.ip
        sudo = self.sudo
        if sudo:
            return "sshpass -p {password} ssh -o StrictHostKeyChecking=no {ip} \"echo {password} | sudo -E -S {cmdline}\"".format(**locals())
        return "sshpass -p {password} ssh -o StrictHostKeyChecking=no {ip} \"{cmdline}\"".format(**locals())

    def run(self, cmdline, ignore_error=False, err_pattern=None, silent=False):
        if not silent:
            log_ssh(self.user, self.ip, cmdline)
        return check_call(self.sshpass_cmdline(cmdline), silent=False)

class RemoteRunner(object):
    def __init__(self, ssh):
        self.ssh = ssh

    def run(self, cmdline, ignore_error=False, err_pattern=None, silent=False):
        return self.ssh.ssh_exec(cmdline, ignore_error=ignore_error, err_pattern=err_pattern, silent=silent)

class _LocalRunner(object):
    def __init__(self):
        pass

    def run(self, cmdline, ignore_error=False, err_pattern=None, silent=False):
        out = check_output(cmdline, ignore_error=ignore_error, silent=silent)
        if err_pattern is not None:
            for line in out.split("\n"):
                if re.search(err_pattern, line):
                    log("ERROR: output matched error pattern for ssh command on other host: {cmdline}".format(**locals()))
                    log(out)
                    sys.exit(1)
        return out

LocalRunner = _LocalRunner()

"""
Run a sudo command and provide the password on the command-line.
xl migrate likes to use nopass_sudo_cmdline (unsure why).
Other commands can use sudo_cmdline.
"""
def nopass_sudo_cmdline(cmdline, password):
    return "sshpass -p {password} sudo -S {cmdline}".format(**locals())
def sudo_cmdline(cmdline, password):
    return "echo {password} | sudo -S {cmdline}".format(**locals())

# def as_pretty_bytes(num, suffix='B'):
#     for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
#         if abs(num) < 1024.0:
#             return "%3.1f%s%s" % (num, unit, suffix)
#         num /= 1024.0
#     return "%.1f%s%s" % (num, 'Yi', suffix)

# see: http://goo.gl/kTQMs
_SYMBOLS = {
    'customary'     : ('B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'),
    'customary_ext' : ('byte', 'kilo', 'mega', 'giga', 'tera', 'peta', 'exa',
                       'zetta', 'iotta'),
    'iec'           : ('Bi', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi', 'Yi'),
    'iec_again'     : ('BiB', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'),
    'iec_ext'       : ('byte', 'kibi', 'mebi', 'gibi', 'tebi', 'pebi', 'exbi',
                       'zebi', 'yobi'),
}

def bytes2human(n, format='%(value).1f %(symbol)s', symbols='customary'):
    """
    Convert n bytes into a human readable string based on format.
    symbols can be either "customary", "customary_ext", "iec" or "iec_ext",
    see: http://goo.gl/kTQMs

      >>> bytes2human(0)
      '0.0 B'
      >>> bytes2human(0.9)
      '0.0 B'
      >>> bytes2human(1)
      '1.0 B'
      >>> bytes2human(1.9)
      '1.0 B'
      >>> bytes2human(1024)
      '1.0 K'
      >>> bytes2human(1048576)
      '1.0 M'
      >>> bytes2human(1099511627776127398123789121)
      '909.5 Y'

      >>> bytes2human(9856, symbols="customary")
      '9.6 K'
      >>> bytes2human(9856, symbols="customary_ext")
      '9.6 kilo'
      >>> bytes2human(9856, symbols="iec")
      '9.6 Ki'
      >>> bytes2human(9856, symbols="iec_ext")
      '9.6 kibi'

      >>> bytes2human(10000, "%(value).1f %(symbol)s/sec")
      '9.8 K/sec'

      >>> # precision can be adjusted by playing with %f operator
      >>> bytes2human(10000, format="%(value).5f %(symbol)s")
      '9.76562 K'
    """
    n = int(n)
    if n < 0:
        raise ValueError("n < 0")
    symbols = _SYMBOLS[symbols]
    prefix = {}
    for i, s in enumerate(symbols[1:]):
        prefix[s] = 1 << (i+1)*10
    for symbol in reversed(symbols[1:]):
        if n >= prefix[symbol]:
            value = float(n) / prefix[symbol]
            return format % locals()
    return format % dict(symbol=symbols[0], value=n)

def human2bytes(s):
    """
    Attempts to guess the string format based on default symbols
    set and return the corresponding bytes as an integer.
    When unable to recognize the format ValueError is raised.

      >>> human2bytes('0 B')
      0
      >>> human2bytes('1 K')
      1024
      >>> human2bytes('1 M')
      1048576
      >>> human2bytes('1 Gi')
      1073741824
      >>> human2bytes('1 tera')
      1099511627776

      >>> human2bytes('0.5kilo')
      512
      >>> human2bytes('0.1  byte')
      0
      >>> human2bytes('1 k')  # k is an alias for K
      1024
      >>> human2bytes('12 foo')
      Traceback (most recent call last):
          ...
      ValueError: can't interpret '12 foo'
    """
    init = s
    num = ""
    while s and s[0:1].isdigit() or s[0:1] == '.':
        num += s[0]
        s = s[1:]
    num = float(num)
    letter = s.strip()
    for name, sset in _SYMBOLS.items():
        if letter in sset:
            break
    else:
        if letter == 'k':
            # treat 'k' as an alias for 'K' as per: http://goo.gl/kTQMs
            sset = _SYMBOLS['customary']
            letter = letter.upper()
        else:
            raise ValueError("can't interpret %r" % init)
    prefix = {sset[0]:1}
    for i, s in enumerate(sset[1:]):
        prefix[s] = 1 << (i+1)*10
    return int(num * prefix[letter])
