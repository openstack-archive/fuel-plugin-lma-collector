.. _system_metrics:

CPU
^^^

Metrics have a ``cpu_number`` field that contains the CPU number to which the
metric applies.

* ``cpu_idle``, the percentage of CPU time spent in the idle task.
* ``cpu_interrupt``, the percentage of CPU time spent servicing interrupts.
* ``cpu_nice``, the percentage of CPU time spent in user mode with low
  priority (nice).
* ``cpu_softirq``, the percentage of CPU time spent servicing soft interrupts.
* ``cpu_steal``, the percentage of CPU time spent in other operating systems.
* ``cpu_system``, the percentage of CPU time spent in system mode.
* ``cpu_user``, the percentage of CPU time spent in user mode.
* ``cpu_wait``, the percentage of CPU time spent waiting for I/O operations to
  complete.


Disk
^^^^

Metrics have a ``device`` field that contains the disk device number the metric
applies to. For example, 'sda', 'sdb', and others.

* ``disk_merged_read``, the number of read operations per second that could be
  merged with already queued operations.
* ``disk_merged_write``, the number of write operations per second that could
  be merged with already queued operations.
* ``disk_octets_read``, the number of octets (bytes) read per second.
* ``disk_octets_write``, the number of octets (bytes) written per second.
* ``disk_ops_read``, the number of read operations per second.
* ``disk_ops_write``, the number of write operations per second.
* ``disk_time_read``, the average time for a read operation to complete in the
  last interval.
* ``disk_time_write``, the average time for a write operation to complete in
  the last interval.

File system
^^^^^^^^^^^

Metrics have a ``fs`` field that contains the partition's mount point to which
the metric applies. For example, '/', '/var/lib', and others.

* ``fs_inodes_free``, the number of free inodes on the file system.
* ``fs_inodes_percent_free``, the percentage of free inodes on the file system.
* ``fs_inodes_percent_reserved``, the percentage of reserved inodes.
* ``fs_inodes_percent_used``, the percentage of used inodes.
* ``fs_inodes_reserved``, the number of reserved inodes.
* ``fs_inodes_used``, the number of used inodes.
* ``fs_space_free``, the number of free bytes.
* ``fs_space_percent_free``, the percentage of free bytes.
* ``fs_space_percent_reserved``, the percentage of reserved bytes.
* ``fs_space_percent_used``, the percentage of used bytes.
* ``fs_space_reserved``, the number of reserved bytes.
* ``fs_space_used``, the number of used bytes.

System load
^^^^^^^^^^^

* ``load_longterm``, the system load average over the last 15 minutes.
* ``load_midterm``, the system load average over the last 5 minutes.
* ``load_shortterm``, the system load average over the last minute.

Memory
^^^^^^

* ``memory_buffered``, the amount of buffered memory in bytes.
* ``memory_cached``, the amount of cached memory in bytes.
* ``memory_free``, the amount of free memory in bytes.
* ``memory_used``, the amount of used memory in bytes.

Network
^^^^^^^

Metrics have an ``interface`` field that contains the interface name the
metric applies to. For example, 'eth0', 'eth1', and others.

* ``if_collisions``, the number of collisions per second per interface.
* ``if_dropped_rx``, the number of dropped packets per second when receiving
  from the interface.
* ``if_dropped_tx``, the number of dropped packets per second when transmitting
  from the interface.
* ``if_errors_rx``, the number of errors per second detected when receiving
  from the interface.
* ``if_errors_rx_crc``, the number of received frames with wrong CRC (cyclic
  redundancy check) per second.
* ``if_errors_rx_fifo``, the number of received frames dropped per second due to
  FIFO buffer overflows.
* ``if_errors_rx_frame``, the number of received frames with invalid frame
  checksum (FCS).
* ``if_errors_rx_length``, the number of received frames with a length that
  doesn't comply with the Ethernet specification.
* ``if_errors_rx_missed``, the number of missed packets when receiving from the
  interface.
* ``if_errors_rx_over``, the number of received frames per second that were
  dropped due to an hardware port receive buffer overflow.
* ``if_errors_tx``, the number of errors per second detected when transmitting
  from the interface.
* ``if_errors_tx_aborted``, the number of aborted frames per second when
  transmitting from the interface
* ``if_errors_tx_carrier``, the number of times per second the interface has
  lost its link connection to the switch.
* ``if_errors_tx_fifo``, the number of transmitted frames per second dropped
  due to FIFO buffer overflows.
* ``if_errors_tx_heartbeat``, the number of heartbeat errors per second.
* ``if_errors_tx_window``, the number of late collisions per second when
  transmitting from the interface.
* ``if_multicast``, the number of multicast packets per second per interface.
* ``if_octets_rx``, the number of octets (bytes) received per second by the
  interface.
* ``if_octets_tx``, the number of octets (bytes) transmitted per second by the
  interface.
* ``if_packets_rx``, the number of packets received per second by the
  interface.
* ``if_packets_tx``, the number of packets transmitted per second by the
  interface.

Processes
^^^^^^^^^

* ``processes_count``, the number of processes in a given state. The metric has
  a ``state`` field (one of 'blocked', 'paging', 'running', 'sleeping',
  'stopped' or 'zombies').
* ``processes_fork_rate``, the number of processes forked per second.

Swap
^^^^

* ``swap_cached``, the amount of cached memory (in bytes) that is in the swap.
* ``swap_free``, the amount of free memory (in bytes) that is in the swap.
* ``swap_io_in``, the number of swap bytes written per second.
* ``swap_io_out``, the number of swap bytes read per second.
* ``swap_used``, the amount of used memory (in bytes) that is in the swap.

Users
^^^^^

* ``logged_users``, the number of users currently logged in.
