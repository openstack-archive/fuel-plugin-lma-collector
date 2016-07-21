.. _LMA_self-monitoring:

System
^^^^^^

The metrics have a ``service`` field with the name of the service it applies
to. The values can be: ``hekad``, ``collectd``, ``influxd``, ``grafana-server``
or ``elasticsearch``.

* ``lma_components_count_processes``, the number of processes currently running.
* ``lma_components_count_threads``, the number of threads currently running.
* ``lma_components_cputime_syst``, the percentage of CPU time spent in system
  mode by the service. It can be greater than 100% when the node has more than
  one CPU.
* ``lma_components_cputime_user``, the percentage of CPU time spent in user
  mode by the service. It can be greater than 100% when the node has more than
  one CPU.
* ``lma_components_disk_bytes_read``, the number of bytes read from disk(s) per
  second.
* ``lma_components_disk_bytes_write``, the number of bytes written to disk(s)
  per second.
* ``lma_components_disk_ops_read``, the number of read operations from disk(s)
  per second.
* ``lma_components_disk_ops_write``, the number of write operations to disk(s)
  per second.
* ``lma_components_memory_code``, the physical memory devoted to executable code
  in bytes.
* ``lma_components_memory_data``, the physical memory devoted to other than
  executable code in bytes.
* ``lma_components_memory_rss``, the non-swapped physical memory used in bytes.
* ``lma_components_memory_vm``, the virtual memory size in bytes.
* ``lma_components_pagefaults_majflt``, major page faults per second.
* ``lma_components_pagefaults_minflt``, minor page faults per second.
* ``lma_components_stacksize``, the absolute value of the start address (the bottom)
  of the stack minus the address of the current stack pointer.

Heka pipeline
^^^^^^^^^^^^^

The metrics have two fields: ``name`` that contains the name of the decoder
or filter as defined by *Heka* and ``type`` that is either *decoder* or
*filter*.

The metrics for both types are as follows:

* ``hekad_memory``, the total memory in bytes used by the Sandbox.
* ``hekad_msg_avg_duration``, the average time in nanoseconds for processing
  the message.
* ``hekad_msg_count``, the total number of messages processed by the decoder.
  This resets to ``0`` when the process is restarted.

Additional metrics for *filter* type:

* ``heakd_timer_event_avg_duration``, the average time in nanoseconds for
  executing the *timer_event* function.
* ``hekad_timer_event_count``, the total number of executions of the
  *timer_event* function. This resets to ``0`` when the process is restarted.

Back-end checks
^^^^^^^^^^^^^^^

* ``http_check``, the API status of the back end, ``1`` if it is responsive,
  if not, then ``0``. The metric contains a ``service`` field that identifies
  the LMA back-end service being checked.

``<service>`` is one of the following values, depending on which Fuel plugins
are deployed in the environment:

* 'influxdb'