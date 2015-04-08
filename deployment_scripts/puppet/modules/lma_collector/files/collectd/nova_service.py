
import dbbase
import collectd

INTERVAL = 15

sql_up = 'select services.binary, count(services.id) as value from services where disabled=0 and deleted=0 and timestampdiff(SECOND,updated_at,utc_timestamp())<60 group by services.binary;'
sql_down = 'select services.binary, count(services.id) as value from services where disabled=0 and deleted=0 and timestampdiff(SECOND,updated_at,utc_timestamp())>60 group by services.binary;'
sql_disabled = 'select services.binary, count(services.id) as value from services where disabled=1 and deleted=0 group by services.binary;'

queries = [
  {
    'name': 'up',
    'query': sql_up,
    'value': 'value',
    'map_col': {'binary': 'services.%s.up'},
  },
  {
    'name': 'down',
    'query': sql_down,
    'value': 'value',
    'map_col': {'binary': 'services.%s.down'},
    'invert': ['up'],
    'invert_value': 0,
  },
  {
    'name': 'disabled',
    'query': sql_disabled,
    'value': 'value',
    'map_col': {'binary': 'services.%s.disabled'},
    'invert': ['up', 'down'],
    'invert_value': 0,
  },
]

class NovaSericeStatusPlugin(dbbase.DBBase):
    """ Class to report the statistics on Nova service.

        number of services by state enabled or disabled
    """

    def get_metrics(self):
        self.plugin = 'nova'
        return  self._map_execute(queries)

plugin = NovaSericeStatusPlugin()

def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)

