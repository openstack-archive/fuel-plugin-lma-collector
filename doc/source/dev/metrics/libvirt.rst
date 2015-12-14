.. _libvirt-metrics:

Every metric contains an ``instance_id`` field which is the UUID of the
instance for the Nova service.

CPU
^^^

* ``virt_cpu_time``, the average amount of CPU time (in nanoseconds) allocated
  to the virtual instance in a second.

* ``virt_vcpu_time``, the average amount of CPU time (in nanoseconds)
  allocated to the virtual CPU in a second. The metric contains a
  ``vcpu_number`` field which is the virtual CPU number.

Disk
^^^^

Metrics have a ``device`` field that contains the virtual disk device to which
the metric applies (eg 'vda', 'vdb' and so on).

* ``virt_disk_octets_read``, the number of octets (bytes) read per second.

* ``virt_disk_octets_write``, the number of octets (bytes) written per second.

* ``virt_disk_ops_read``, the number of read operations per second.

* ``virt_disk_ops_write``, the number of write operations per second.

Memory
^^^^^^

* ``virt_memory_total``, the total amount of memory (in bytes) allocated to the
  virtual instance.

Network
^^^^^^^

Metrics have a ``interface`` field that contains the interface name to which
the metric applies (eg 'tap0dc043a6-dd', 'tap769b123a-2e' and so on).

* ``virt_if_dropped_rx``, the number of dropped packets per second when
  receiving from the interface.

* ``virt_if_dropped_tx``, the number of dropped packets per second when
  transmitting from the interace.

* ``virt_if_errors_rx``, the number of errors per second detected when
  receiving from the interface.

* ``virt_if_errors_tx``, the number of errors per second detected when
  transmitting from the interace.

* ``virt_if_octets_rx``, the number of octets (bytes) received per second by
  the interace.

* ``virt_if_octets_tx``, the number of octets (bytes) transmitted per second by
  the interface.

* ``virt_if_packets_rx``, the number of packets received per second by the
  interace.

* ``virt_if_packets_tx``, the number of packets transmitted per second by the
  interface.
