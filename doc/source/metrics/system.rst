.. _system_metrics:

CPU
^^^

Metrics have a ``cpu_number`` field that contains the CPU number to which the metric applies.

* ``cpu_idle``, percentage of CPU time spent in the idle task.
* ``cpu_interrupt``, percentage of CPU time spent servicing interrupts.
* ``cpu_nice``, percentage of CPU time spent in user mode with low priority (nice).
* ``cpu_softirq``, percentage of CPU time spent servicing soft interrupts.
* ``cpu_steal``, percentage of CPU time spent in other operating systems.
* ``cpu_system``, percentage of CPU time spent in system mode.
* ``cpu_user``, percentage of CPU time spent in user mode.
* ``cpu_wait``, percentage of CPU time spent waiting for I/O operations to complete.


Disk
^^^^

Metrics have a ``device`` field that contains the disk device number to which the metric applies (eg 'sda', 'sdb' and so on).

* ``disk_merged_read``, the number of read operations per second that could be merged with already queued operations.
* ``disk_merged_write``, the number of write operations per second that could be merged with already queued operations.
* ``disk_octets_read``, the number of octets (bytes) read per second.
* ``disk_octets_write``, the number of octets (bytes) written per second.
* ``disk_ops_read``, the number of read operations per second.
* ``disk_ops_write``, the number of write operations per second.
* ``disk_time_read``, the average time for a read operation to complete in the last interval.
* ``disk_time_write``, the average time for a write operation to complete in the last interval.

File system
^^^^^^^^^^^

Metrics have a ``fs`` field that contains the partition's mount point to which the metric applies (eg '/', '/var/lib' and so on).

* ``fs_inodes_free``, the number of free inodes on the file system.
* ``fs_inodes_reserved``, the number of reserved inodes.
* ``fs_inodes_used``, the number of used inodes.
* ``fs_space_free``, the number of free bytes.
* ``fs_space_reserved``, the number of reserved bytes.
* ``fs_space_used``, the number of used bytes.
* ``fs_inodes_percent_free``, the percentage of free inodes on the file system.
* ``fs_inodes_percent_reserved``, the percentage of reserved inodes.
* ``fs_inodes_percent_used``, the percentage of used inodes.
* ``fs_space_percent_free``, the percentage of free bytes.
* ``fs_space_percent_reserved``, the percentage of reserved bytes.
* ``fs_space_percent_used``, the percentage of used bytes.

System load
^^^^^^^^^^^

* ``load_longterm``, the system load average over the last 15 minutes.
* ``load_midterm``, the system load average over the last 5 minutes.
* ``load_shortterm``, the system load averge over the last minute.

Memory
^^^^^^

* ``memory_buffered``, the amount of memory (in bytes) which is buffered.
* ``memory_cached``, the amount of memory (in bytes) which is cached.
* ``memory_free``, the amount of memory (in bytes) which is free.
* ``memory_used``, the amount of memory (in bytes) which is used.

Network
^^^^^^^

Metrics have a ``interface`` field that contains the interface name to which the metric applies (eg 'eth0', 'eth1' and so on).

* ``if_errors_rx``, the number of errors per second detected when receiving from the interface.
* ``if_errors_tx``, the number of errors per second detected when transmitting from the interace.
* ``if_octets_rx``, the number of octets (bytes) received per second by the interace.
* ``if_octets_tx``, the number of octets (bytes) transmitted per second by the interface.
* ``if_packets_rx``, the number of packets received per second by the interace.
* ``if_packets_tx``, the number of packets transmitted per second by the interface.

Processes
^^^^^^^^^

* ``processes_fork_rate``, the number of processes forked per second.
* ``processes_count``, the number of processes in a given state. The metric has
  a ``state`` field (one of 'blocked', 'paging', 'running', 'sleeping', 'stopped'
  or 'zombies').

Swap
^^^^

* ``swap_cached``, the amount of cached memory (in bytes) which is in the swap.
* ``swap_free``, the amount of free memory (in bytes) which is in the swap.
* ``swap_used``, the amount of used memory (in bytes) which is in the swap.

* ``swap_io_in``, the number of swap pages written per second.
* ``swap_io_out``, the number of swap pages read per second.

Users
^^^^^

* ``logged_users``, the number of users currently logged-in.
