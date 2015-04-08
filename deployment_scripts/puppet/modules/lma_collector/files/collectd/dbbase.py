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

import base
import sqlalchemy

class DBBase(base.Base):
    def __init__(self, *args, **kwargs):
        super(DBBase, self).__init__(*args, **kwargs)
        self.engine = None
        self.cnx_string = None

    def config_callback(self, conf):
        super(DBBase, self).config_callback(conf)
        for node in conf.children:
            if node.key == "Connection":
                self.cnx_string = node.values[0]
        self.engine = sqlalchemy.create_engine(self.cnx_string)

    @staticmethod
    def _invert(q, cache):
        metrics = {}
        for invert in q['invert']:
            if invert not in cache:
                continue
            for r in cache[invert]:
                for key in q['map_col']:
                    metric = q['map_col'][key] % r[key]
                    metrics[metric] = q['invert_value']
        return metrics

    def _map_execute(self, queries):
        metrics = {}
        cache = {}
        try:
            conn = self.engine.connect()
            for q in queries:
                query = q['query']
                n = q['name']
                try:
                    result = conn.execute(query)
                    rows = result.fetchall()
                    if 'invert' in q:
                        mm = self._invert(q, cache)
                        metrics.update(mm)

                    cache[n] = rows
                    for r in rows:
                        for key in q['map_col']:
                            metric = q['map_col'][key] % r[key]
                            metrics[metric] = r[q['value']]
                except sqlalchemy.exc.SQLAlchemyError as e:
                    collectd.error(str(e))
        finally:
            conn.close()
        return metrics
