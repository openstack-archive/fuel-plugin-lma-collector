.. _user_upgrade_from_0_8_0_to_0_8_1:

Upgrade StackLight 0.8.0 to 0.8.1 on MOS 7.0
============================================

Prerequisite
------------

1. We suppose that StackLight 0.8.0 is installed, up and running::

    $ fuel plugins
    id | name                        | version | package_version
    ---|-----------------------------|---------|----------------
    2  | influxdb_grafana            | 0.8.0   | 3.0.0
    3  | lma_collector               | 0.8.0   | 2.0.0
    4  | lma_infrastructure_alerting | 0.8.0   | 3.0.0
    1  | elasticsearch_kibana        | 0.8.0   | 3.0.0


Installation Steps of the minor upgrade
---------------------------------------

1. Build all plugins that are tagged 0.8.1rc2
2. Copy them on fuel master node
3. Update them::

    $ fuel plugins --update elasticsearch_kibana-0.8-0.8.1-1.noarch.rpm
    $ fuel plugins --update influxdb_grafana-0.8-0.8.1-1.noarch.rpm
    $ fuel plugins --update lma_collector-0.8-0.8.1-1.noarch.rpm
    $ fuel plugins --update lma_infrastructure_alerting-0.8-0.8.1-1.noarch.rpm

At this point all new plugins should be installed::

    $ fuel plugins
    id | name                        | version | package_version
    ---|-----------------------------|---------|----------------
    2  | influxdb_grafana            | 0.8.1   | 3.0.0
    3  | lma_collector               | 0.8.1   | 3.0.0
    1  | elasticsearch_kibana        | 0.8.1   | 3.0.0
    4  | lma_infrastructure_alerting | 0.8.1   | 3.0.0


Before upgrading to StackLight 0.8.1 you need to stop all hekad and collectd
processes and you need to remove the package of heka that is currently
installed. This is done by running the following scripts on
*/var/www/nailgun/plugins/lma_collector-0.8/contrib/tools* on the Fuel master
node::

    $ stop_services.sh # it stops hekad and collectd on all nodes
    $ remove_heka_package.sh # it removes heka package. It is needed to fix an
                             # issue with package that doesn't respect the
                             # naming convention that prevents the upgrade of
                             # heka from 0.10.0b1 to 0.10.0.

1. You need to login to the node where Elasticsearch is running and create a
   snapshot of your data. The procedure is described in "Procedure to snapshot
   and restore Elasticsearch data"

2. Now you can do the upgrade. Run tasks from post_deployment and wait the end
   of deployment between each steps.  You can follow the status of the deployment
   by looking in the puppet.log of the corresponding node what is currently
   running. For example you can do::

    ssh node-X tail -f /var/log/puppet.log

3. On StackLight backend nodes (i.e. nodes with role elasticsearch_kibana
   and/or role influxdb_grafana and/or role infrastructure_alerting). Let's
   say it is node-A1, node-A2 and node-A3 if StackLight backends are deployed
   on three different nodes (otherwise it will be only on node-A1). It may be
   noted that nodes will be rebooted::

    fuel node --node A1,A2,A3 --tasks post_deployment_start

4. You need to log to the node where Elasticsearch is running and restore the
   snapshot created before the upgrade. See the procedure to restore snapshot
   in the "Procedure to snapshot and restore Elasticsearch data" for all
   details.

5. On controller nodes. Let say it is node-B1, node-B2 and node-B3::

    fuel node --node B1,B2,B3 --tasks post_deployment_start

6. On compute nodes. Let say it is node-C1 (but of course you can have several
   computes)::

    fuel node --node C1 --tasks post_deployment_start


Procedure to snapshot and restore Elasticsearch data
----------------------------------------------------

We describe how to do a snapshot and restore it. The snapshot will be done
before the upgrade and the restore will be done after.

Create a snapshot
~~~~~~~~~~~~~~~~~

We need to create a snapshot of indices because during the upgrade the
configuration of Elasticsearch will be modified and directory under
*/var/lib* won't be used anymore

Before the upgrade

1. Create a directory for snapshot (you need to be sure that there is enough
   space in the directory you are using and elasticsearch user can write on
   it)::

    $ curl -XPUT -d '{"type":"fs","settings":{"location":"/opt/es-data/elasticsearch_data/snapshots/stacklight"}}' 'http://localhost:9200/_snapshot/stacklight?pretty'


   Result should be::

    {
      "acknowledged" : true
    }

2. Verify the directory::

    $ curl -XPOST 'http://localhost:9200/_snapshot/stacklight/_verify?pretty'

   Result should be something like::

    {
      "nodes" : {
          "2kDiN_FSS5OtUvpwzRp0Eg" : {
              "name" : "node-1-es-01"
          }
      }
    }

3. Create the snapshot::

    $ curl -XPUT 'http://localhost:9200/_snapshot/stacklight/snap1?wait_for_completion=true&pretty' -d '{"ignore_unavailable":"true","indice_global_state":"false","compress":"true"}'

   Result should be something like::

    {
      "snapshot" : {
            "snapshot" : "snap1",
            "indices" : [ "kibana-int", "notification-2016.03.23", "log-2016.03.25", "log-2016.03.23", "log-2016.03.24" ],
            "state" : "SUCCESS",
            "start_time" : "2016-03-25T13:11:46.120Z",
            "start_time_in_millis" : 1458911506120,
            "end_time" : "2016-03-25T13:12:11.899Z",
            "end_time_in_millis" : 1458911531899,
            "duration_in_millis" : 25779,
            "failures" : [ ],
            "shards" : {
              "total" : 17,
              "failed" : 0,
              "successful" : 17
            }
      }
    }

Restore procedure
~~~~~~~~~~~~~~~~~

1. Close all indexes::

    $ curl -XPOST 'http://localhost:9200/_all/_close'

   Result should be something like::

    {
      "Acknowledged":true
    }


2. Restore the snapshot::

    $ curl -XPOST 'http://localhost:9200/_snapshot/stacklight/snap1/_restore?pretty'


   Result should be something like::

    {
      "accepted" : true
    }

Checks that upgrade succeeded
-----------------------------

Check on all nodes
~~~~~~~~~~~~~~~~~~

* Check that there are no errors in logs (for collectd, LMA)
* Check that there is only one process of collectd and one process of hekad that is running::

    $ ssh node-X pidof collectd
    3947
    $ ssh node-X pidof hekad
    22270

* Check that Heka has been updated::

    $ hekad --version
    0.10.0

* Check that buffering has been activated (let check into output_elasticsearch.toml) [3]::

    $ cat output-elasticsearch.toml
    [elasticsearch_output]
    type = "ElasticSearchOutput"
    message_matcher = "Type == 'log' || Type  == 'notification'"
    encoder = "elasticsearch_encoder"

    flush_interval = 5000
    flush_count = 10

    server = "http://10.109.2.4:9200"

    use_buffering = true

    [elasticsearch_output.buffering]
    max_buffer_size = 1073741824
    max_file_size = 134217728
    full_action = "drop"

* [TODO] Check that log rotation is correct [5][6]

Check on all nodes but controller
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Check that the LMA wrapper script is not forking heka (not for controller) by looking for the usage of the exec [4]::

    # cat /usr/local/bin/lma_collector_wrapper
    #!/bin/sh
    HEKAD="/usr/bin/hekad"

    exec $HEKAD -config=/etc/lma_collector

* Check that upstart file has been updated (not needed for controller), we don’t use sudo command any more [4]::

    root@node-2:~# cat /etc/init/lma_collector.conf
    # lma_collector

    description         "lma_collector"


    start on runlevel [2345]
    stop on runlevel [!2345]


    respawn


    pre-start script
            touch /var/log/lma_collector.log
            chown heka:heka /var/log/lma_collector.log
    end script


    script
            # https://bugs.launchpad.net/lma-toolchain/+bug/1543289
            ulimit -n 102400
            exec start-stop-daemon --start  --user heka --exec /usr/local/bin/lma_collector_wrapper 2>>/var/log/lma_collector.log
    end script


Check only on compute nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Check only on controller nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Check that resource lma_collector is working fine from pacemaker point of view::

    # crm resource status lma_collector
    resource lma_collector is running on: node-3.test.domain.local


* Ulimit in OCF script: /usr/lib/ocf/resource.d/fuel/ocf-lma_collector::

    # grep ulimit /usr/lib/ocf/resource.d/fuel/ocf-lma_collector
    ulimit -n 102400


Check only on elasticsearch node
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Check that curator has been updated in the crontab [1]::

    # crontab -l
    ...
    0 2 * * * /usr/local/bin/curator --host localhost --port 9200 --debug delete indices --regex '^(log|notification)-.*$' --time-unit days --older-than 31 --timestring "\%Y.\%m.\%d"


* Check that data path for Elasticsearch has been updated [2]::

    # grep data /etc/elasticsearch/es-01/elasticsearch.yml
      data: /opt/es-data/elasticsearch_data/es-01

* Check that current data path is /opt/es-data/elasticsearch_data/es-01::

    # curl -s localhost:9200/_nodes?pretty |grep data
         "data" : "/opt/es-data/elasticsearch_data/es-01",

Check only on influxdb node
~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Check that there is only one file for the log rotation of influxdb
* Check that permissions are 644 for this file::

    # ls -l /etc/logrotate.d/ |grep influx
    -rw-r--r--   1 root root  113 Sep 29 17:51 influxd

* [Patch in review]  Check that http logs have been disabled in the configuration file
   * You shouldn't see lines starting '[http]' in */var/log/influxdb/influxd.log*

Check only on alerting node
~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Check Nagios (Apache) is still running

Rollback
--------

Not supported and irrelevant. Fuel doesn't support the possibility to rollback the upgrade of a plugin.


Related bugs
------------

[1] https://bugs.launchpad.net/lma-toolchain/+bug/1535435
[2] https://bugs.launchpad.net/lma-toolchain/+bug/1559126
[3] https://bugs.launchpad.net/fuel-plugins/+bug/1557388
[4] https://bugs.launchpad.net/lma-toolchain/+bug/1560946
[5] https://bugs.launchpad.net/fuel-plugins/+bug/1561603
[6] https://bugs.launchpad.net/fuel-plugins/+bug/1561605
