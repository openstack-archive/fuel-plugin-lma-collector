.. _HAproxy_metrics:

Server
^^^^^^

* ``haproxy.connections``, Number of current connections.
* ``haproxy.ssl.connections``, Number of current SSL connections.
* ``haproxy.run_queue``, Number of connections waiting in the queue.
* ``haproxy.tasks``, Number of tasks.
* ``haproxy.uptime_seconds``, HAproxy server uptime in seconds.

Frontends
^^^^^^^^^

Metrics per frontend:

* ``haproxy.frontend.<frontend>.bytes_in``, Number of bytes received by the frontend.
* ``haproxy.frontend.<frontend>.bytes_out``, Number of bytes emitted by the frontend.
* ``haproxy.frontend.<frontend>.denied_requests``, Number of denied requests.
* ``haproxy.frontend.<frontend>.denied_responses``, Number of denied responses.
* ``haproxy.frontend.<frontend>.error_requests``, Number of error requests.
* ``haproxy.frontend.<frontend>.response_1xx``, Number of http responses with 1xx code.
* ``haproxy.frontend.<frontend>.response_2xx``, Number of http responses with 2xx code.
* ``haproxy.frontend.<frontend>.response_3xx``, Number of http responses with 3xx code.
* ``haproxy.frontend.<frontend>.response_4xx``, Number of http responses with 4xx code.
* ``haproxy.frontend.<frontend>.response_5xx``, Number of http responses with 5xx code.
* ``haproxy.frontend.<frontend>.response_other``, Number of http responses with other code.
* ``haproxy.frontend.<frontend>.session_current``, Number of current sessions.
* ``haproxy.frontend.<frontend>.session_total``, Derivative of total number of connections.


Backends
^^^^^^^^

Metrics per backends:

* ``haproxy.backend.<backend>.bytes_in``, Number of bytes received by the backend.
* ``haproxy.backend.<backend>.bytes_out``, Number of bytes emitted by the backend.
* ``haproxy.backend.<backend>.denied_requests``, Number of denied requests.
* ``haproxy.backend.<backend>.denied_responses``, Number of denied responses.
* ``haproxy.backend.<backend>.downtime``, Total downtime in second.
* ``haproxy.backend.<backend>.error_connection``, Number of error connections.
* ``haproxy.backend.<backend>.error_responses``, Number of error responses.
* ``haproxy.backend.<backend>.queue_current``, Number of requests in queue.
* ``haproxy.backend.<backend>.redistributed``, Number of times a request was redispatched to another server.
* ``haproxy.backend.<backend>.response_1xx``, Number of http responses with 1xx code.
* ``haproxy.backend.<backend>.response_2xx``, Number of http responses with 2xx code.
* ``haproxy.backend.<backend>.response_3xx``, Number of http responses with 3xx code.
* ``haproxy.backend.<backend>.response_4xx``, Number of http responses with 4xx code.
* ``haproxy.backend.<backend>.response_5xx``, Number of http responses with 5xx code.
* ``haproxy.backend.<backend>.response_other``, Number of http responses with other code.
* ``haproxy.backend.<backend>.retries``, Number of times a connection to a server was retried.
* ``haproxy.backend.<backend>.session_current``, Number of current sessions.
* ``haproxy.backend.<backend>.session_total``, Cumulative number of connections.

where frontend and backend are one of:

* cinder-api
* glance-api
* glance-registry
* heat-api
* heat-api-cfn
* heat-api-cloudwatch
* horizon
* keystone-1
* keystone-2
* mysqld
* neutron
* nova-api-1
* nova-api-2
* nova-metadata-api
* nova-novncproxy
* sahara
* murano
* stats
* swift

