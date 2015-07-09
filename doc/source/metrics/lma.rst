.. _LMA_self-monitoring:

System
^^^^^^

* ``lma_components.<service>.count.processes``, number of processes currently running.
* ``lma_components.<service>.count.threads``, number of threads currently running.
* ``lma_components.<service>.cputime.user``, percentage of CPU time spent in user mode by the service. It can be greater than 100% when the node has more than one CPU.
* ``lma_components.<service>.cputime.syst``, percentage of CPU time spent in system mode by the service. It can be greater than 100% when the node has more than one CPU.
* ``lma_components.<service>.disk.bytes.read``, number of bytes read from disk(s) per second.
* ``lma_components.<service>.disk.bytes.write``, number of bytes written to disk(s) per second.
* ``lma_components.<service>.disk.ops.read``, number of read operations from disk(s) per second.
* ``lma_components.<service>.disk.ops.write``, number of write operations to disk(s) per second.
* ``lma_components.<service>.memory.code``,  physical memory devoted to executable code (bytes).
* ``lma_components.<service>.memory.data``, physical memory devoted to other than executable code (bytes).
* ``lma_components.<service>.memory.rss``, non-swapped physical memory used (bytes).
* ``lma_components.<service>.memory.vm``, virtual memory size (bytes).
* ``lma_components.<service>.pagefaults.minflt``, minor page faults per second.
* ``lma_components.<service>.pagefaults.majflt``, major page faults per second.
* ``lma_components.<service>.stacksize``, absolute value of the address of the start (i.e., bottom) of the stack minus the current value of the stack pointer.

Where ``<service>`` is *hekad*, *collectd*, *influxdb* or *elasticsearch*
depending of what is running on the node.


Heka pipeline
^^^^^^^^^^^^^

* ``lma_components.hekad.decoder.<name>.count``, the total number of messages processed by the decoder. This will reset to 0 when the process is restarted.
* ``lma_components.hekad.decoder.<name>.duration``, the average time for processing the message (in nanoseconds).
* ``lma_components.hekad.filter.<name>.count``, the total number of messages processed by the filter. This will reset to 0 when the process is restarted.
* ``lma_components.hekad.filter.<name>.duration``, the average time for processing the message (in nanoseconds).

``<name>`` is the internal name of the decoder or the filter used by *Heka*.
