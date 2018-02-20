#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import re
import sys
from os.path import join as _j

import dot_util

SSH_CONFIG_ATTRS = [
    'User',
    'IdentityFile',
    'ProxyCommand',
    'ForwardX11',
    'HostName',
]

DEFAULT_SSH_CONFIG = _j(dot_util.HOME, '.ssh/config')

class SSHConfigParser(object):
    def __init__(self, ssh_config):
        self.ssh_config = ssh_config
        self._host = None
        self._attrs = None
        self.config = None

    def parse_host(self, line):
        m = re.search(r'^Host\s+(?P<hostname>.*)\s*', line)
        if not m:
            return False
        if self._host is not None:
            self._record_host()
        self._host = m.group('hostname')
        return True

    def _record_host(self):
        assert self._host is not None
        if self._host in self.config:
            raise RuntimeError("Failed to parse {ssh_config}; Host {host} occured twice.".format(
                host=self._host,
                ssh_config=self.ssh_config))
        self.config[self._host] = self._attrs
        self._attrs = {}
        self._host = None

    ATTR_RE = r'(?:(?:[A-Z][a-z]*)+)'
    def parse_attr(self, line):
        m = re.search('^\s+(?P<attr>{ATTR_RE})\s+(?P<value>.*)'.format(
            ATTR_RE=SSHConfigParser.ATTR_RE), line)
        if not m:
            return False
        attr = m.group('attr')
        value = m.group('value').rstrip()
        self._attrs[attr] = value

    def strip_comments(self, line):
        return re.sub(r'#.*', '', line)

    def parse(self):
        self.config = {}

        with open(self.ssh_config) as f:
            for line in f:
                line = self.strip_comments(line)
                line = line.rstrip()
                if self.parse_host(line):
                    continue
                if self.parse_attr(line):
                    continue
            if self._host is not None:
                self._record_host()

        return self.config

class SSHConfig(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

        self.ssh_config_parser = SSHConfigParser(self.args.ssh_config)

    def check_args(self):
        parser = self.parser
        args = self.args

        if len(self.attrs_asked_for) != 1:
            parser.error("Need you to ask for exactly one SSH config attribute (e.g. --user), but saw you asking for: {attrs_asked_for}".format(
                attrs_asked_for=self.attrs_asked_for
            ))

    def main(self):
        args = self.args
        parser = self.parser

        config = self.ssh_config_parser.parse()

        if self.args.host not in config:
            parser.error('no HostName = {host} found in {ssh_config}'.format(
                host=self.args.host,
                ssh_config=self.args.ssh_config,
            ))
        attrs = config[self.args.host]
        # Whatever option they provided that is NOT false
        attr_name = self.attrs_asked_for[0]
        if attr_name not in attrs:
            parser.error('no attr = {attr} found in config for Host = {host}'.format(
                host=self.args.host,
                attr=attr_name,
            ))
        value = attrs[attr_name]
        if self.args.no_newline:
            sys.stdout.write(value)
        else:
            print(value)

    @staticmethod
    def _option_name(ssh_name, sep="_"):
        """
        Host -> host
        IdentityFile -> identity<sep>file
        ...
        """
        # 'I', 'dentity', 'F', 'ile'
        splits = [x for x in re.split(r'([A-Z])', ssh_name) if x != '']
        # ('I', 'dentity'), ('F', 'ile')
        groups = list(groups_of(splits, 2))
        # 'identity', 'file'
        joined_groups = [(p0 + p1).lower() for p0, p1 in groups]
        option_name = sep.join(joined_groups)
        return option_name

    @staticmethod
    def option_name(ssh_name):
        """
        Host -> host
        IdentityFile -> --identity-file
        ...
        """
        return "--" + SSHConfig._option_name(ssh_name, sep='-')

    @staticmethod
    def argname(ssh_name):
        """
        Host -> host
        IdentityFile -> identity_file
        ...
        """
        return SSHConfig._option_name(ssh_name, sep='_')

    @staticmethod
    def ssh_name(option_name):
        """
        host -> Host
        identity_file -> IdentityFile
        ...
        """
        ssh_name = ''.join(x.title() for x in re.split(r'_', option_name))
        return ssh_name

    @property
    def attrs_asked_for(self):
        attrs_asked_for = [attr for attr in SSH_CONFIG_ATTRS if self.is_set(attr)]
        return attrs_asked_for

    def is_set(self, ssh_name):
        argname = self.argname(ssh_name)
        assert argname in self.args
        assert type(getattr(self.args, argname)) == bool
        return getattr(self.args, argname)

def take(n, ys):
    it = iter(ys)
    while n > 0:
        yield next(it)
        n -= 1

def groups_of(xs, n):
    """
    groups_of([1,2,3,4], 2)
    >>> (1,2), (3,4)
    groups_of([1,2,3], 2)
    >>> (1,2), (3,)
    """
    it = iter(xs)
    while True:
        tup = tuple(take(n, it))
        if len(tup) == 0:
            break
        yield tup

def main():
    parser = argparse.ArgumentParser("Extract stuff from ~/.ssh/config from Host = --host")
    parser.add_argument("--ssh-config", default=DEFAULT_SSH_CONFIG)
    parser.add_argument("--host", required=True,
                        help="'Host' in the ssh config file")
    parser.add_argument('-n', '--no-newline', action='store_true',
                        help="Don't print newline")
    def add_arg(ssh_name):
        option_name = SSHConfig.option_name(ssh_name)
        parser.add_argument(option_name, action='store_true',
                            help="get {ssh_name}".format(**locals()))
    for ssh_name in SSH_CONFIG_ATTRS:
        add_arg(ssh_name)
    args = parser.parse_args()

    ssh_config = SSHConfig(args, parser)
    ssh_config.check_args()
    ssh_config.main()

if __name__ == "__main__":
    main()
