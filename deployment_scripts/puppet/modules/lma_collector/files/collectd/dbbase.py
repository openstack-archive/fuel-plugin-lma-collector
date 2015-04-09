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
    def _invert(q, cache, metrics):
        for invert in q['invert']:
            if invert not in cache:
                continue
            for r in cache[invert]:
                for key in q['map_to_metric']:
                    if 'rename_func' in q:
                        metric = q['map_to_metric'][key] % q['rename_func'][key](r[key])
                    else:
                        metric = q['map_to_metric'][key] % r[key]
                    if metric not in metrics:
                        metrics[metric] = q['invert_value']
        return metrics

    def queries_to_metrics(self, queries_map):
        """ map SQL queries results to metrics.

        queries_map: a list of query dict with following keys:
         'name': uniq name of the query.
         'query': the SQL query string.
         'value': the name of the column used for metrics value.
         'value_func': a function to normalize the value for all entries.
         'map_to_metric: a dict to map column to metric name
                         {<column-name> : <metric-name-with-placeholder-%s>}.
         'rename_func': a function to rename metric names, apply to all metrics.

        Optionals keys:
         'value_map_func': a dict {name: function} to normalize values per <column-name> entry,
                           take precedence over 'value_func'.
         'invert': a list of query name to create missing metrics for
                   the current query.
         'invert_value': the default value to use when inverting.
        """

        metrics = {}
        cache = {}
        conn = self.engine.connect()
        try:
            for q in queries_map:
                query = q['query']
                n = q['name']
                result = conn.execute(query)
                rows = result.fetchall()
                for r in rows:
                    for key in q['map_to_metric']:
                        if 'rename_func' in q:
                            metric = q['map_to_metric'][key] % q['rename_func'][key](r[key])
                        else:
                            metric = q['map_to_metric'][key] % r[key]

                        if 'value_map_func' in q and r[key] in q['value_map_func']:
                            metrics[metric] = q['value_map_func'][r[key]](r[q['value']])
                        elif q['value_func']:
                            metrics[metric] = q['value_func'](r[q['value']])
                        else:
                            metrics[metric] = r[q['value']]

                cache[n] = rows
        except sqlalchemy.exc.SQLAlchemyError as e:
            self.logger.error(str(e))
        finally:
            conn.close()

        for q in queries_map:
            if 'invert' in q:
                mm = self._invert(q, cache, metrics)
                metrics.update(mm)
        return metrics
