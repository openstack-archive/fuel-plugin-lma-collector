.. _alarm_list:

Appendix C: List of built-in alarms
===================================

Here is a list of all the alarms that are built-in in StackLight::

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
            threshold: 5
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
            threshold: 2
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
            threshold: 5
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
            threshold: 2
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
              backend: 'swift-api'
            relational_operator: '>'
            threshold: 0
            window: 60
            periods: 1
            function: diff
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
    - name: 'keystone-logs-error'
      description: 'Too many errors have been detected in Keystone logs'
      severity: 'warning'
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
            threshold: 20
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
            threshold: 15
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

