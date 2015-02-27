.. _system_metrics:

CPU
^^^

* ``cpu.<cpu number>.idle``, percentage of CPU time spent in the idle task.
* ``cpu.<cpu number>.interrupt``, percentage of CPU time spent servicing interrupts.
* ``cpu.<cpu number>.nice``, percentage of CPU time spent in user mode with low priority (nice).
* ``cpu.<cpu number>.softirq``, percentage of CPU time spent servicing soft interrupts.
* ``cpu.<cpu number>.steal``, percentage of CPU time spent in other operating systems.
* ``cpu.<cpu number>.system``, percentage of CPU time spent in system mode.
* ``cpu.<cpu numbner>.user``, percentage of CPU time spent in user mode.
* ``cpu.<cpu number>.wait``, percentage of CPU time spent waiting for I/O operations to complete.

``<cpu number>`` expands to 0, 1, 2, and so on.


Disk
^^^^

* ``disk.<disk device>.disk_merged.read``, the number of read operations per second that could be merged with already queued operations.
* ``disk.<disk device>.disk_merged.write``, the number of write operations per second that could be merged with already queued operations.
* ``disk.<disk device>.disk_octets.read``, the number of octets (bytes) read per second.
* ``disk.<disk device>.disk_octets.write``, the number of octets (bytes) written per second.
* ``disk.<disk device>.disk_ops.read``, the number of read operations per second.
* ``disk.<disk device>.disk_ops.write``, the number of write operations per second.
* ``disk.<disk device>.disk_time.read``, the average time for a read operation to complete in the last interval.
* ``disk.<disk device>.disk_time.write``, the average time for a write operation to complete in the last interval.

``<disk device>`` expands to 'sda', 'sdb' and so on.

File system
^^^^^^^^^^^

* ``fs.<mount point>.inodes.free``, the number of free inodes on the file system.
* ``fs.<mount point>.inodes.reserved``, the number of reserved inodes.
* ``fs.<mount point>.inodes.used``, the number of used inodes.
* ``fs.<mount point>.space.free``, the number of free bytes.
* ``fs.<mount point>.space.reserved``, the number of reserved bytes.
* ``fs.<mount point>.space.used``, the number of used bytes.

``<mount point>`` expands to 'root' for '/', 'boot' for '/boot', 'var-lib' for '/var/lib' and so on.

System load
^^^^^^^^^^^

* ``load.longterm``, the system load average over the last 15 minutes.
* ``load.midterm``, the system load average over the last 5 minutes.
* ``load.shortterm``, the system load averge over the last minute.

Memory
^^^^^^

* ``memory.buffered``, the amount of memory (in bytes) which is buffered.
* ``memory.cached``, the amount of memory (in bytes) which is cached.
* ``memory.free``, the amount of memory (in bytes) which is free.
* ``memory.used``, the amount of memory (in bytes) which is used.

Network
^^^^^^^

* ``net.<interface>.if_errors.rx``, the number of errors per second detected when receiving from the interface.
* ``net.<interface>.if_errors.tx``, the number of errors per second detected when transmitting from the interace.
* ``net.<interface>.if_octets.rx``, the number of octets (bytes) received per second by the interace.
* ``net.<interface>.if_octets.tx``, the number of octets (bytes) transmitted per second by the interface.
* ``net.<interface>.if_packets.rx``, the number of packets received per second by the interace.
* ``net.<interface>.if_packets.tx``, the number of packets transmitted per second by the interface.

``<interface>`` expands to the interface name, eg 'br-mgmt', 'br-storage' and so on.

Processes
^^^^^^^^^

* ``processes.fork_rate``, the number of processes forked per second.
* ``processes.state.blocked``, the number of processes in blocked state.
* ``processes.state.paging``, the number of processes in paging state.
* ``processes.state.running``, the number of processes in running state.
* ``processes.state.sleeping``, the number of processes in sleeping state.
* ``processes.state.stopped``, the number of processes in stopped state.
* ``processes.state.zombies``, the number of processes in zombie state.

Swap
^^^^

* ``swap.cached``, the amount of cached memory (in bytes) which is in the swap.
* ``swap.free``, the amount of free memory (in bytes) which is in the swap.
* ``swap.used``, the amount of used memory (in bytes) which is in the swap.

* ``swap_io.in``, the number of swap pages written per second.
* ``swap_io.out``, the number of swap pages read per second.

Users
^^^^^

* ``users.users``, the number of users currently logged-in.
