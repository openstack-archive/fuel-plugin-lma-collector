.. _LMA_self-monitoring:

* ``lma_components.<process name>.ps_code``,  physical memory devoted to executable code (bytes).
* ``lma_components.<process name>.ps_count``, number of threads currently running.
* ``lma_components.<process name>.ps_cputime``, time that this process has been scheduled in user/system mode in the last interval (in microseconds).
* ``lma_components.<process name>.ps_data``, physical memory devoted to other than executable code (bytes).
* ``lma_components.<process name>.ps_disk_octets``, number of bytes the task has caused to be read or written from storage in the last interval.
* ``lma_components.<process name>.ps_disk_ops``, number of read and write I/O operations in the last interval, i.e. syscalls like read(), pread().
* ``lma_components.<process name>.ps_pagefaults``, minor and major page faults in the last interval.
* ``lma_components.<process name>.ps_rss``, non-swapped physical memory used (bytes).
* ``lma_components.<process name>.ps_stacksize``, absolute value of the address of the start (i.e., bottom) of the stack minus the current value of the stack pointer.
* ``lma_components.<process name>.ps_vm``, virtual memory size (bytes).

Where ``<process name>`` is *hekad*, *collectd*, *influxdb* or *elasticsearch*
depending of what is running on the node.
