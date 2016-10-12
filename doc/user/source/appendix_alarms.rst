.. _alarms:

.. raw:: latex

   \pagebreak

List of built-in alarms
-----------------------

The following is a list of StackLight built-in alarms::

  alarms:
    - name: 'cpu-critical-controller'
      description: 'The CPU usage is too high (controller node)'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 5
            window: 120
            periods: 0
            function: avg
          - metric: cpu_wait
            relational_operator: '>='
            threshold: 35
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-warning-controller'
      description: 'The CPU usage is high (controller node)'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 15
            window: 120
            periods: 0
            function: avg
          - metric: cpu_wait
            relational_operator: '>='
            threshold: 25
            window: 120
            periods: 0
            function: avg
    - name: 'swap-usage-critical'
      description: 'There is no more swap free space'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: swap_free
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: max
    - name: 'swap-activity-warning'
      description: 'The swap activity is high'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: swap_io_in
            relational_operator: '>='
            threshold: 1048576 # 1 Mb/s
            window: 120
            periods: 0
            function: avg
          - metric: swap_io_out
            relational_operator: '>='
            threshold: 1048576 # 1 Mb/s
            window: 120
            periods: 0
            function: avg
    - name: 'swap-usage-warning'
      description: 'The swap free space is low'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: swap_percent_used
            relational_operator: '>='
            threshold: 0.8
            window: 60
            periods: 0
            function: avg
    - name: 'cpu-critical-compute'
      description: 'The CPU usage is too high (compute node)'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_wait
            relational_operator: '>='
            threshold: 30
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-warning-compute'
      description: 'The CPU usage is high (compute node)'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_wait
            relational_operator: '>='
            threshold: 20
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-critical-rabbitmq'
      description: 'The CPU usage is too high (RabbitMQ node)'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 5
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-warning-rabbitmq'
      description: 'The CPU usage is high (RabbitMQ node)'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 15
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-critical-mysql'
      description: 'The CPU usage is too high (MySQL node)'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 5
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-warning-mysql'
      description: 'The CPU usage is high (MySQL node)'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 15
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-critical-storage'
      description: 'The CPU usage is too high (storage node)'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_wait
            relational_operator: '>='
            threshold: 40
            window: 120
            periods: 0
            function: avg
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 5
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-warning-storage'
      description: 'The CPU usage is high (storage node)'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_wait
            relational_operator: '>='
            threshold: 30
            window: 120
            periods: 0
            function: avg
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 15
            window: 120
            periods: 0
            function: avg
    - name: 'cpu-critical-default'
      description: 'The CPU usage is too high'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: cpu_wait
            relational_operator: '>='
            threshold: 35
            window: 120
            periods: 0
            function: avg
          - metric: cpu_idle
            relational_operator: '<='
            threshold: 5
            window: 120
            periods: 0
            function: avg
    - name: 'rabbitmq-disk-limit-critical'
      description: 'RabbitMQ has reached the free disk threshold. All producers are blocked'
      severity: 'critical'
      # If the local RabbitMQ instance is down, it will be caught by the
      # rabbitmq-check alarm
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: rabbitmq_remaining_disk
            relational_operator: '<='
            threshold: 0
            window: 20
            periods: 0
            function: min
    - name: 'rabbitmq-disk-limit-warning'
      description: 'RabbitMQ is getting close to the free disk threshold'
      severity: 'warning'
      # If the local RabbitMQ instance is down, it will be caught by the
      # rabbitmq-check alarm
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: rabbitmq_remaining_disk
            relational_operator: '<='
            threshold: 104857600 # 100MB
            window: 20
            periods: 0
            function: min
    - name: 'rabbitmq-memory-limit-critical'
      description: 'RabbitMQ has reached the memory threshold. All producers are blocked'
      severity: 'critical'
      # If the local RabbitMQ instance is down, it will be caught by the
      # rabbitmq-check alarm
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: rabbitmq_remaining_memory
            relational_operator: '<='
            threshold: 0
            window: 20
            periods: 0
            function: min
    - name: 'rabbitmq-memory-limit-warning'
      description: 'RabbitMQ is getting close to the memory threshold'
      severity: 'warning'
      # If the local RabbitMQ instance is down, it will be caught by the
      # rabbitmq-check alarm
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: rabbitmq_remaining_memory
            relational_operator: '<='
            threshold: 104857600 # 100MB
            window: 20
            periods: 0
            function: min
    - name: 'rabbitmq-queue-warning'
      description: 'The number of outstanding messages is too high'
      severity: 'warning'
      # If the local RabbitMQ instance is down, it will be caught by the
      # rabbitmq-check alarm
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: rabbitmq_messages
            relational_operator: '>='
            threshold: 200
            window: 120
            periods: 0
            function: avg
    - name: 'rabbitmq-pacemaker-down'
      description: 'The RabbitMQ cluster is down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        logical_operator: 'and'
        rules:
          - metric: pacemaker_resource_percent
            fields:
              resource: rabbitmq
              status: up
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'rabbitmq-pacemaker-critical'
      description: 'The RabbitMQ cluster is critical because less than half of the nodes are up'
      severity: 'critical'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        logical_operator: 'and'
        rules:
          - metric: pacemaker_resource_percent
            fields:
              resource: rabbitmq
              status: up
            relational_operator: '<'
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'rabbitmq-pacemaker-warning'
      description: 'The RabbitMQ cluster is degraded because some RabbitMQ nodes are missing'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        logical_operator: 'and'
        rules:
          - metric: pacemaker_resource_percent
            fields:
              resource: rabbitmq
              status: up
            relational_operator: '<'
            threshold: 100
            window: 60
            periods: 0
            function: last
    - name: 'apache-warning'
      description: 'There is no Apache idle workers available'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: apache_idle_workers
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: min
    - name: 'apache-check'
      description: 'Apache cannot be checked'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: apache_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'log-fs-warning'
      description: "The log filesystem's free space is low"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/log'
            relational_operator: '<'
            threshold: 10
            window: 60
            periods: 0
            function: min
    - name: 'log-fs-critical'
      description: "The log filesystem's free space is too low"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/log'
            relational_operator: '<'
            threshold: 5
            window: 60
            periods: 0
            function: min
    - name: 'root-fs-warning'
      description: "The root filesystem's free space is low"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/'
            relational_operator: '<'
            threshold: 10
            window: 60
            periods: 0
            function: min
    - name: 'root-fs-critical'
      description: "The root filesystem's free space is too low"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/'
            relational_operator: '<'
            threshold: 5
            window: 60
            periods: 0
            function: min
    - name: 'mysql-fs-warning'
      description: "The MySQL filesystem's free space is low"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/lib/mysql'
            relational_operator: '<'
            threshold: 10
            window: 60
            periods: 0
            function: min
    - name: 'mysql-fs-critical'
      description: "The MySQL filesystem's free space is too low"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/lib/mysql'
            relational_operator: '<'
            threshold: 5
            window: 60
            periods: 0
            function: min
    - name: 'nova-fs-warning'
      description: "The filesystem's free space is low (compute node)"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/lib/nova'
            relational_operator: '<'
            threshold: 10
            window: 60
            periods: 0
            function: min
    - name: 'nova-fs-critical'
      description: "The filesystem's free space is too low (compute node)"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/lib/nova'
            relational_operator: '<'
            threshold: 5
            window: 60
            periods: 0
            function: min
    - name: 'other-fs-warning'
      description: "The filesystem's free space is low"
      severity: 'warning'
      enabled: 'true'
      no_data_policy: 'okay'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '!= /var/lib/nova && != /var/log && != /var/lib/mysql && != / && !~ ceph%-%d+$'
            group_by: [fs]
            relational_operator: '<'
            threshold: 10
            window: 60
            periods: 0
            function: min
    - name: 'other-fs-critical'
      description: "The filesystem's free space is too low"
      severity: 'critical'
      enabled: 'true'
      no_data_policy: 'okay'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '!= /var/lib/nova && != /var/log && != /var/lib/mysql && != / && !~ ceph%-%d+$'
            group_by: [fs]
            relational_operator: '<'
            threshold: 5
            window: 60
            periods: 0
            function: min
    - name: 'osd-disk-critical'
      description: "The filesystem's free space is too low (OSD disk)"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              # Real FS is /var/lib/ceph/osd/ceph-0 but Collectd substituted '/' by '-'
              fs: '=~ ceph/%d+$'
            group_by: [fs]
            relational_operator: '<'
            threshold: 5
            window: 60
            periods: 0
            function: min
    - name: 'nova-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on nova-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'nova-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'nova-logs-error'
      description: 'Too many errors have been detected in Nova logs'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: log_messages
            fields:
              service: 'nova'
              level: 'error'
            relational_operator: '>'
            threshold: 0.1
            window: 70
            periods: 0
            function: max
    - name: 'heat-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on heat-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'heat-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'heat-logs-error'
      description: 'Too many errors have been detected in Heat logs'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: log_messages
            fields:
              service: 'heat'
              level: 'error'
            relational_operator: '>'
            threshold: 0.1
            window: 70
            periods: 0
            function: max
    - name: 'swift-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on swift-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'swift-api || object-storage'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'swift-logs-error'
      description: 'Too many errors have been detected in Swift logs'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: log_messages
            fields:
              service: 'swift'
              level: 'error'
            relational_operator: '>'
            threshold: 0.1
            window: 70
            periods: 0
            function: max
    - name: 'cinder-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on cinder-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'cinder-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'cinder-logs-error'
      description: 'Too many errors have been detected in Cinder logs'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: log_messages
            fields:
              service: 'cinder'
              level: 'error'
            relational_operator: '>'
            threshold: 0.1
            window: 70
            periods: 0
            function: max
    - name: 'glance-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on glance-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'glance-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'glance-logs-error'
      description: 'Too many errors have been detected in Glance logs'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: log_messages
            fields:
              service: 'glance'
              level: 'error'
            relational_operator: '>'
            threshold: 0.1
            window: 70
            periods: 0
            function: max
    - name: 'neutron-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on neutron-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'neutron-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'neutron-logs-error'
      description: 'Too many errors have been detected in Neutron logs'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: log_messages
            fields:
              service: 'neutron'
              level: 'error'
            relational_operator: '>'
            threshold: 0.1
            window: 70
            periods: 0
            function: max
    - name: 'keystone-response-time-duration'
      description: 'Keystone API is too slow'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: openstack_keystone_http_response_times
            fields:
              http_method: '== GET || == POST'
              http_status: '!= 5xx'
            relational_operator: '>'
            threshold: 0.3
            window: 60
            periods: 0
            value: upper_90
            function: max
    - name: 'keystone-public-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on keystone-public-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'keystone-public-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'keystone-admin-api-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on keystone-admin-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'keystone-admin-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'horizon-web-http-errors'
      description: 'Too many 5xx HTTP errors have been detected on horizon'
      severity: 'warning'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: haproxy_backend_response_5xx
            fields:
              backend: 'horizon-web || horizon-https'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
    - name: 'keystone-logs-error'
      description: 'Too many errors have been detected in Keystone logs'
      severity: 'warning'
      no_data_policy: 'okay'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: log_messages
            fields:
              service: 'keystone'
              level: 'error'
            relational_operator: '>'
            threshold: 0.1
            window: 70
            periods: 0
            function: max
    - name: 'mysql-node-connected'
      description: 'The MySQL service has lost connectivity with the other nodes'
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: mysql_cluster_connected
            relational_operator: '=='
            threshold: 0
            window: 30
            periods: 1
            function: min
    - name: 'mysql-node-ready'
      description: "The MySQL service isn't ready to serve queries"
      severity: 'critical'
      enabled: 'true'
      trigger:
        logical_operator: 'or'
        rules:
          - metric: mysql_cluster_ready
            relational_operator: '=='
            threshold: 0
            window: 30
            periods: 1
            function: min
    - name: 'ceph-health-critical'
      description: 'Ceph health is critical'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: ceph_health
            relational_operator: '=='
            threshold: 3 # HEALTH_ERR
            window: 60
            function: max
    - name: 'ceph-health-warning'
      description: 'Ceph health is warning'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: ceph_health
            relational_operator: '=='
            threshold: 2 # HEALTH_WARN
            window: 60
            function: max
    - name: 'ceph-capacity-critical'
      description: 'Ceph free capacity is too low'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: ceph_pool_total_percent_free
            relational_operator: '<'
            threshold: 2
            window: 60
            function: max
    - name: 'ceph-capacity-warning'
      description: 'Ceph free capacity is low'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: ceph_pool_total_percent_free
            relational_operator: '<'
            threshold: 5
            window: 60
            function: max
    - name: 'elasticsearch-health-critical'
      description: 'Elasticsearch cluster health is critical'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: elasticsearch_cluster_health
            relational_operator: '=='
            threshold: 3 # red
            window: 60
            function: min
    - name: 'elasticsearch-health-warning'
      description: 'Elasticsearch health is warning'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: elasticsearch_cluster_health
            relational_operator: '=='
            threshold: 2 # yellow
            window: 60
            function: min
    - name: 'elasticsearch-fs-warning'
      description: "The filesystem's free space is low (Elasticsearch node)"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/opt/es/data' # Real FS is /opt/es-data but Collectd substituted '/' by '-'
            relational_operator: '<'
            threshold: 20 # The low watermark for disk usage is 85% by default
            window: 60
            periods: 0
            function: min
    - name: 'elasticsearch-fs-critical'
      description: "The filesystem's free space is too low (Elasticsearch node)"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/opt/es/data' # Real FS is /opt/es-data but Collectd substituted '/' by '-'
            relational_operator: '<'
            threshold: 15 # The high watermark for disk usage is 90% by default
            window: 60
            periods: 0
            function: min
    - name: 'influxdb-fs-warning'
      description: "The filesystem's free space is low (InfluxDB node)"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/lib/influxdb'
            relational_operator: '<'
            threshold: 10
            window: 60
            periods: 0
            function: min
    - name: 'influxdb-fs-critical'
      description: "The filesystem's free space is too low (InfluxDB node)"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: fs_space_percent_free
            fields:
              fs: '/var/lib/influxdb'
            relational_operator: '<'
            threshold: 5
            window: 60
            periods: 0
            function: min
    - name: 'haproxy-check'
      description: "HAProxy cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'rabbitmq-check'
      description: "RabbitMQ cannot be checked"
      # This alarm's severity is warning because the effective status of the
      # RabbitMQ cluster is computed by rabbitmq-pacemaker-* alarms.
      # This alarm is still useful because it will report the node(s) on which
      # RabbitMQ isn't running.
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: rabbitmq_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'ceph-mon-check'
      description: "Ceph monitor cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: ceph_mon_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'ceph-osd-check'
      description: "Ceph OSD cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: ceph_osd_check
            relational_operator: '=='
            threshold: 0
            window: 80  # The metric interval collection is 60s
            periods: 0
            function: last
    - name: 'pacemaker-check'
      description: "Pacemaker cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: pacemaker_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'elasticsearch-check'
      description: "Elasticsearch cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: elasticsearch_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'influxdb-check'
      description: "InfluxDB cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: influxdb_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'libvirt-check'
      description: "Libvirt cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: libvirt_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'memcached-check'
      description: "memcached cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: memcached_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'mysql-check'
      description: "MySQL cannot be checked"
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: mysql_check
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'network-warning-dropped-rx'
      description: "Some received packets have been dropped"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: if_dropped_rx
            relational_operator: '>'
            threshold: 100
            window: 60
            periods: 0
            function: avg
    - name: 'network-critical-dropped-rx'
      description: "Too many received packets have been dropped"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: if_dropped_rx
            relational_operator: '>'
            threshold: 1000
            window: 60
            periods: 0
            function: avg
    - name: 'network-warning-dropped-tx'
      description: "Some transmitted packets have been dropped"
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: if_dropped_tx
            relational_operator: '>'
            threshold: 100
            window: 60
            periods: 0
            function: avg
    - name: 'network-critical-dropped-tx'
      description: "Too many transmitted packets have been dropped"
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: if_dropped_tx
            relational_operator: '>'
            threshold: 1000
            function: avg
            window: 60
    - name: 'instance-creation-time-warning'
      description: "Instance creation takes too much time"
      severity: 'warning'
      no_data_policy: 'okay' # This is a sporadic metric
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_instance_creation_time
            relational_operator: '>'
            threshold: 20
            window: 600
            periods: 0
            function: avg
    - name: 'hdd-errors-critical'
      description: 'Errors on hard drive(s) have been detected'
      severity: 'critical'
      enabled: 'true'
      no_data_policy: okay
      trigger:
        rules:
          - metric: hdd_errors_rate
            group_by: ['device']
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: max
    - name: 'total-nova-free-vcpu-warning'
      description: 'There is none VCPU available for new instances'
      severity: 'warning'
      enabled: 'true'
      no_data_policy: skip # the metric is only collected from the aggregator node
      trigger:
        rules:
          - metric: openstack_nova_total_free_vcpus
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: max
    - name: 'total-nova-free-memory-warning'
      description: 'There is none memory available for new instances'
      severity: 'warning'
      enabled: 'true'
      no_data_policy: skip  # the metric is only collected from the aggregator node
      trigger:
        rules:
          - metric: openstack_nova_total_free_ram
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: max

    # Adds alarm on local check for OpenStack services endpoint
    - name: 'cinder-api-local-endpoint'
      description: 'Cinder API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'cinder-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'glance-api-local-endpoint'
      description: 'Glance API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'glance-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-api-local-endpoint'
      description: 'Heat API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'heat-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-cfn-api-local-endpoint'
      description: 'Heat CFN API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'heat-cfn-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'keystone-public-api-local-endpoint'
      description: 'Keystone public API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'keystone-public-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-api-local-endpoint'
      description: 'Neutron API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'neutron-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-api-local-endpoint'
      description: 'Nova API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'nova-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'swift-api-local-endpoint'
      description: 'Swift API is locally down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_local_api
            fields:
              service: 'swift-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last

    # Following are the OpenStack service check API definitions and
    # also InfluxDB API
    - name: 'influxdb-api-check-failed'
      description: 'Endpoint check for InfluxDB is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: http_check
            fields:
              service: 'influxdb-cluster'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-api-check-failed'
      description: 'Endpoint check for nova-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'nova-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-api-check-failed'
      description: 'Endpoint check for neutron-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'neutron-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-api-check-failed'
      description: 'Endpoint check for cinder-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'cinder-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-v2-api-check-failed'
      description: 'Endpoint check for cinder-v2-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'cinder-v2-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'glance-api-check-failed'
      description: 'Endpoint check for glance-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'glance-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-api-check-failed'
      description: 'Endpoint check for heat-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'heat-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-cfn-api-check-failed'
      description: 'Endpoint check for heat-cfn-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'heat-cfn-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'swift-api-check-failed'
      description: 'Endpoint check for swift-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'swift-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'swift-s3-api-check-failed'
      description: 'Endpoint check for swift-s3-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'swift-s3-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'keystone-public-api-check-failed'
      description: 'Endpoint check for keystone-public-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'keystone-public-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'ceilometer-api-check-failed'
      description: 'Endpoint check for ceilometer-api is failed'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the controller running the management VIP
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_check_api
            fields:
              service: 'ceilometer-api'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last

    # Following are the AFD generated to check API backends
    # All backends are down
    - name: 'elasticsearch-api-backends-all-down'
      description: 'All Elasticsearch backends are down'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'elasticsearch-rest'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'kibana-api-backends-all-down'
      description: 'All API backends are down for Kibana'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'kibana'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'influxdb-api-backends-all-down'
      description: 'All API backends are down for InfluxDB'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'influxdb'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'grafana-api-backends-all-down'
      description: 'All API backends are down for Grafana'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'grafana'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'glance-registry-api-backends-all-down'
      description: 'All API backends are down for glance-registry-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'glance-registry-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-api-backends-all-down'
      description: 'All API backends are down for nova-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'nova-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-api-backends-all-down'
      description: 'All API backends are down for cinder-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'cinder-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'object-storage-api-backends-all-down'
      description: 'All API backends are down for object-storage'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'object-storage'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-cfn-api-backends-all-down'
      description: 'All API backends are down for heat-cfn-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'heat-cfn-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'horizon-web-api-backends-all-down'
      description: 'All API backends are down for horizon-web'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'horizon-web || horizon-https'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-novncproxy-websocket-api-backends-all-down'
      description: 'All API backends are down for nova-novncproxy-websocket'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'nova-novncproxy-websocket'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-api-backends-all-down'
      description: 'All API backends are down for heat-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'heat-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'keystone-public-api-backends-all-down'
      description: 'All API backends are down for keystone-public-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'keystone-public-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-cloudwatch-api-backends-all-down'
      description: 'All API backends are down for heat-cloudwatch-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'heat-cloudwatch-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-metadata-api-backends-all-down'
      description: 'All API backends are down for nova-metadata-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'nova-metadata-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'mysqld-tcp-api-backends-all-down'
      description: 'All API backends are down for mysqld-tcp'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'mysqld-tcp'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'keystone-admin-api-backends-all-down'
      description: 'All API backends are down for keystone-admin-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'keystone-admin-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'glance-api-backends-all-down'
      description: 'All API backends are down for glance-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'glance-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-api-backends-all-down'
      description: 'All API backends are down for neutron-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'neutron-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'swift-api-backends-all-down'
      description: 'All API backends are down for swift-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'swift-api || object-storage'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'ceilometer-api-backends-all-down'
      description: 'All API backends are down for ceilometer-api'
      severity: 'down'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'ceilometer-api'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    # At least one backend is down
    - name: 'elasticsearch-api-backends-one-down'
      description: 'At least one API backend is down for elasticsearch'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'elasticsearch-rest'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'kibana-api-backends-one-down'
      description: 'At least one API backend is down for kibana'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'kibana'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'influxdb-api-backends-one-down'
      description: 'At least one API backend is down for influxdb'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'influxdb'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'grafana-api-backends-one-down'
      description: 'At least one API backend is down for grafana'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'grafana'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'glance-registry-api-backends-one-down'
      description: 'At least one API backend is down for glance-registry-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'glance-registry-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-api-backends-one-down'
      description: 'At least one API backend is down for nova-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'nova-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-api-backends-one-down'
      description: 'At least one API backend is down for cinder-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'cinder-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'object-storage-api-backends-one-down'
      description: 'At least one API backend is down for object-storage'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'object-storage'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-cfn-api-backends-one-down'
      description: 'At least one API backend is down for heat-cfn-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'heat-cfn-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'horizon-web-api-backends-one-down'
      description: 'At least one API backend is down for horizon-web'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'horizon-web || horizon-https'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-novncproxy-websocket-api-backends-one-down'
      description: 'At least one API backend is down for nova-novncproxy-websocket'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'nova-novncproxy-websocket'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-api-backends-one-down'
      description: 'At least one API backend is down for heat-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'heat-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'keystone-public-api-backends-one-down'
      description: 'At least one API backend is down for keystone-public-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'keystone-public-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'heat-cloudwatch-api-backends-one-down'
      description: 'At least one API backend is down for heat-cloudwatch-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'heat-cloudwatch-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-metadata-api-backends-one-down'
      description: 'At least one API backend is down for nova-metadata-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'nova-metadata-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'mysqld-tcp-api-backends-one-down'
      description: 'At least one API backend is down for mysqld-tcp'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'mysqld-tcp'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'keystone-admin-api-backends-one-down'
      description: 'At least one API backend is down for keystone-admin-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'keystone-admin-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'glance-api-backends-one-down'
      description: 'At least one API backend is down for glance-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'glance-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-api-backends-one-down'
      description: 'At least one API backend is down for neutron-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'neutron-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'swift-api-backends-one-down'
      description: 'At least one API backend is down for swift-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'swift-api || object-storage'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'ceilometer-api-backends-one-down'
      description: 'At least one API backend is down for ceilometer-api'
      severity: 'warning'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers
            fields:
              backend: 'ceilometer-api'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    # Less than 50% of backends are up
    - name: 'elasticsearch-api-backends-majority-down'
      description: 'Less than 50% of backends are up for elasticsearch'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'elasticsearch-rest'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'kibana-api-backends-majority-down'
      description: 'Less than 50% of backends are up for kibana'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'kibana'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'influxdb-api-backends-majority-down'
      description: 'Less than 50% of backends are up for influxdb'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'influxdb'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'grafana-api-backends-majority-down'
      description: 'Less than 50% of backends are up for grafana'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'grafana'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'glance-registry-api-backends-majority-down'
      description: 'Less than 50% of backends are up for glance-registry-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'glance-registry-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'nova-api-backends-majority-down'
      description: 'Less than 50% of backends are up for nova-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'nova-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'cinder-api-backends-majority-down'
      description: 'Less than 50% of backends are up for cinder-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'cinder-api'
              state: 'up'

            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'object-storage-api-backends-majority-down'
      description: 'Less than 50% of backends are up for object-storage'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'object-storage'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'heat-cfn-api-backends-majority-down'
      description: 'Less than 50% of backends are up for heat-cfn-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'heat-cfn-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'horizon-web-api-backends-majority-down'
      description: 'Less than 50% of backends are up for horizon-web'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'horizon-web || horizon-https'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'nova-novncproxy-websocket-api-backends-majority-down'
      description: 'Less than 50% of backends are up for nova-novncproxy-websocket'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'nova-novncproxy-websocket'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'heat-api-backends-majority-down'
      description: 'Less than 50% of backends are up for heat-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'heat-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'keystone-public-api-backends-majority-down'
      description: 'Less than 50% of backends are up for keystone-public-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'keystone-public-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'heat-cloudwatch-api-backends-majority-down'
      description: 'Less than 50% of backends are up for heat-cloudwatch-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'heat-cloudwatch-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'nova-metadata-api-backends-majority-down'
      description: 'Less than 50% of backends are up for nova-metadata-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'nova-metadata-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'mysqld-tcp-api-backends-majority-down'
      description: 'Less than 50% of backends are up for mysqld-tcp'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'mysqld-tcp'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'keystone-admin-api-backends-majority-down'
      description: 'Less than 50% of backends are up for keystone-admin-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'keystone-admin-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'glance-api-backends-majority-down'
      description: 'Less than 50% of backends are up for glance-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'glance-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'neutron-api-backends-majority-down'
      description: 'Less than 50% of backends are up for neutron-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'neutron-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'swift-api-backends-majority-down'
      description: 'Less than 50% of backends are up for swift-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'swift-api || object-storage'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'ceilometer-api-backends-majority-down'
      description: 'Less than 50% of backends are up for ceilometer-api'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: haproxy_backend_servers_percent
            fields:
              backend: 'ceilometer-api'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last

    # Following are the AFD generated to check workers
    # All workers are down
    - name: 'nova-scheduler-all-down'
      description: 'All Nova schedulers are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'scheduler'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-cert-all-down'
      description: 'All Nova certs are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'cert'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-consoleauth-all-down'
      description: 'All Nova consoleauths are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'consoleauth'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-compute-all-down'
      description: 'All Nova computes are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'compute'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-conductor-all-down'
      description: 'All Nova conductors are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'conductor'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-scheduler-all-down'
      description: 'All Cinder schedulers are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_cinder_services
            fields:
              service: 'scheduler'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-volume-all-down'
      description: 'All Cinder volumes are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_cinder_services
            fields:
              service: 'volume'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-l3-all-down'
      description: 'All Neutron L3 agents are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'l3'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-dhcp-all-down'
      description: 'All Neutron DHCP agents are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'dhcp'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-metadata-all-down'
      description: 'All Neutron metadata agents are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'metadata'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-openvswitch-all-down'
      description: 'All Neutron openvswitch agents are down'
      severity: 'down'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'openvswitch'
              state: 'up'
            relational_operator: '=='
            threshold: 0
            window: 60
            periods: 0
            function: last
    # At least one backend is down
    - name: 'nova-scheduler-one-down'
      description: 'At least one Nova scheduler is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'scheduler'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-cert-one-down'
      description: 'At least one Nova cert is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'cert'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-consoleauth-one-down'
      description: 'At least one Nova consoleauth is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'consoleauth'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-compute-one-down'
      description: 'At least one Nova compute is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'compute'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'nova-conductor-one-down'
      description: 'At least one Nova conductor is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services
            fields:
              service: 'conductor'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-scheduler-one-down'
      description: 'At least one Cinder scheduler is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_cinder_services
            fields:
              service: 'scheduler'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'cinder-volume-one-down'
      description: 'At least one Cinder volume is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_cinder_services
            fields:
              service: 'volume'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-l3-one-down'
      description: 'At least one L3 agent is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'l3'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-dhcp-one-down'
      description: 'At least one DHCP agent is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'dhcp'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-metadata-one-down'
      description: 'At least one metadata agents is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'metadata'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    - name: 'neutron-openvswitch-one-down'
      description: 'At least one openvswitch agents is down'
      severity: 'warning'
      no_data_policy: 'skip' # the metric is only collected from the DC node
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents
            fields:
              service: 'openvswitch'
              state: 'down'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 0
            function: last
    # Less than 50% of service are up (compared to up and down).
    - name: 'nova-scheduler-majority-down'
      description: 'Less than 50% of Nova schedulers are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services_percent
            fields:
              service: 'scheduler'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'nova-cert-majority-down'
      description: 'Less than 50% of Nova certs are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services_percent
            fields:
              service: 'cert'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'nova-consoleauth-majority-down'
      description: 'Less than 50% of Nova consoleauths are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services_percent
            fields:
              service: 'consoleauth'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'nova-compute-majority-down'
      description: 'Less than 50% of Nova computes are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services_percent
            fields:
              service: 'compute'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'nova-conductor-majority-down'
      description: 'Less than 50% of Nova conductors are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_nova_services_percent
            fields:
              service: 'conductor'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'cinder-scheduler-majority-down'
      description: 'Less than 50% of Cinder schedulers are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_cinder_services_percent
            fields:
              service: 'scheduler'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'cinder-volume-majority-down'
      description: 'Less than 50% of Cinder volumes are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_cinder_services_percent
            fields:
              service: 'volume'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'neutron-l3-majority-down'
      description: 'Less than 50% of Neutron L3 agents are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents_percent
            fields:
              service: 'l3'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'neutron-dhcp-majority-down'
      description: 'Less than 50% of Neutron DHCP agents are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents_percent
            fields:
              service: 'dhcp'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'neutron-metadata-majority-down'
      description: 'Less than 50% of Neutron metadata agents are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents_percent
            fields:
              service: 'metadata'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
    - name: 'neutron-openvswitch-majority-down'
      description: 'Less than 50% of Neutron openvswitch agents are up'
      severity: 'critical'
      enabled: 'true'
      trigger:
        rules:
          - metric: openstack_neutron_agents_percent
            fields:
              service: 'openvswitch'
              state: 'up'
            relational_operator: '<='
            threshold: 50
            window: 60
            periods: 0
            function: last
