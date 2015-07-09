.. _LMA_self-monitoring:

Processes and memory
^^^^^^^^^^^^^^^^^^^^

* ``lma_components.<service>.count.processes``, number of processes currently running.
* ``lma_components.<service>.count.threads``, number of threads currently running.
* ``lma_components.<service>.cputime.user``, time that this process has been scheduled in user mode in the last interval (in microseconds).
* ``lma_components.<service>.cputime.syst``, time that this process has been scheduled in system mode in the last interval (in microseconds).
* ``lma_components.<service>.disk.bytes.read``, number of bytes the task has caused to be read from storage in the last interval.
* ``lma_components.<service>.disk.bytes.write``, number of bytes the task has caused to be written from storage in the last interval.
* ``lma_components.<service>.disk.ops.read``, number of read I/O operations in the last interval, i.e. syscalls like read(), pread().
* ``lma_components.<service>.disk.ops.write``, number of write I/O operations in the last interval, i.e. syscalls like write(), pwrite().
* ``lma_components.<service>.memory.code``,  physical memory devoted to executable code (bytes).
* ``lma_components.<service>.memory.data``, physical memory devoted to other than executable code (bytes).
* ``lma_components.<service>.memory.rss``, non-swapped physical memory used (bytes).
* ``lma_components.<service>.memory.vm``, virtual memory size (bytes).
* ``lma_components.<service>.pagefaults.minflt``, minor page faults in the last interval.
* ``lma_components.<service>.pagefaults.majflt``, major page faults in the last interval.
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
