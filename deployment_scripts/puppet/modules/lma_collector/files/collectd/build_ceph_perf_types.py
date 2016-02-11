#!/usr/bin/python
# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import json
import os
import subprocess
import sys


class CephPerfCollectionSchema(object):

    def __init__(self, collection, schema):
        self.collection = collection
        self.schema = schema

    def __str__(self):
        def sanitize(s):
            return s.replace('::', '_').replace('-', '_').lower()

        return '\n'.join(['%s_%s value:GAUGE:U:U' % (sanitize(self.collection),
                                                     sanitize(k))
                          for k in sorted(self.schema.iterkeys())])


class CephPerfSchema(object):

    def __init__(self, socket_path):
        self.socket_path = socket_path

    @staticmethod
    def run_command(cmd):
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            (stdout, stderr) = proc.communicate()
            stdout = stdout.rstrip('\n')
        except Exception as e:
            print("Cannot execute command '%s': %s" % (cmd, str(e)))
            raise e

        return json.loads(stdout)

    def ceph_version(self):
        cmd = ['/usr/bin/ceph', '--admin-daemon', self.socket_path, 'version']
        return self.run_command(cmd).get('version')

    def itertypes(self):
        cmd = ['/usr/bin/ceph', '--admin-daemon', self.socket_path, 'perf',
               'schema']

        for collection, schema in self.run_command(cmd).iteritems():
            yield CephPerfCollectionSchema(collection, schema)


def main():
    script_name = os.path.basename(sys.argv[0])
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("usage: %s <Ceph OSD socket> [namespace]" % script_name)
    else:
        schema = CephPerfSchema(sys.argv[1])
        collection = sys.argv[2] if len(sys.argv) == 3 else None
        print("# File generated automatically by the %s script" % script_name)
        print("# Ceph version: %s" % schema.ceph_version())
        for item in schema.itertypes():
            if collection is None or item.collection == collection:
                print(item)

if __name__ == '__main__':
    main()
