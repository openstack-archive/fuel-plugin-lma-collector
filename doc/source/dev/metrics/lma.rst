.. _LMA_self-monitoring:

System
^^^^^^

Metrics have a ``service`` field with the name of the service it applies to. Values can be: hekad, collectd, influxd, grafana-server or elasticsearch.

* ``lma_components_count_processes``, number of processes currently running.
* ``lma_components_count_threads``, number of threads currently running.
* ``lma_components_cputime_user``, percentage of CPU time spent in user mode by the service. It can be greater than 100% when the node has more than one CPU.
* ``lma_components_cputime_syst``, percentage of CPU time spent in system mode by the service. It can be greater than 100% when the node has more than one CPU.
* ``lma_components_disk_bytes_read``, number of bytes read from disk(s) per second.
* ``lma_components_disk_bytes_write``, number of bytes written to disk(s) per second.
* ``lma_components_disk_ops_read``, number of read operations from disk(s) per second.
* ``lma_components_disk_ops_write``, number of write operations to disk(s) per second.
* ``lma_components_memory_code``,  physical memory devoted to executable code (bytes).
* ``lma_components_memory_data``, physical memory devoted to other than executable code (bytes).
* ``lma_components_memory_rss``, non-swapped physical memory used (bytes).
* ``lma_components_memory_vm``, virtual memory size (bytes).
* ``lma_components_pagefaults_minflt``, minor page faults per second.
* ``lma_components_pagefaults_majflt``, major page faults per second.
* ``lma_components_stacksize``, absolute value of the address of the start (i.e., bottom) of the stack minus the current value of the stack pointer.

Heka pipeline
^^^^^^^^^^^^^

Metrics have two fields: ``name`` that contains the name of the decoder or filter as defined by *Heka* and ``type`` that is either *decoder* or *filter*.

Metrics for both types:

* ``hekad_msg_avg_duration``, the average time for processing the message (in nanoseconds).
* ``hekad_msg_count``, the total number of messages processed by the decoder. This will reset to 0 when the process is restarted.
* ``hekad_memory``, the total memory used by the Sandbox (in bytes).

Additional metrics for *filter* type:

* ``heakd_timer_event_avg_duration``, the average time for executing the *timer_event* function (in nanoseconds).
* ``hekad_timer_event_count``, the total number of executions of the *timer_event* function. This will reset to 0 when the process is restarted.

Backend checks
^^^^^^^^^^^^^^

* ``http_check``, the backend's API status, 1 if it is responsive, 0 otherwise.
  The metric contains a ``service`` field that identifies the LMA backend service being checked.

``<service>`` is one of the following values (depending of which Fuel plugins are deployed in the environment) with their respective resource checks:

* 'influxdb'
