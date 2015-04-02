.. _haproxy_metrics:

Server
^^^^^^

* ``haproxy.status``, the status of the HAProxy service, 1 if it is responsive,
  0 otherwise.
* ``haproxy.connections``, number of current connections.
* ``haproxy.ssl_connections``, number of current SSL connections.
* ``haproxy.run_queue``, number of connections waiting in the queue.
* ``haproxy.tasks``, number of tasks.
* ``haproxy.uptime``, HAProxy server uptime in seconds.

Frontends
^^^^^^^^^

Metrics per frontend:

* ``haproxy.frontend.<frontend>.bytes_in``, number of bytes received by the frontend.
* ``haproxy.frontend.<frontend>.bytes_out``, number of bytes transmitted by the frontend.
* ``haproxy.frontend.<frontend>.denied_requests``, number of denied requests.
* ``haproxy.frontend.<frontend>.denied_responses``, number of denied responses.
* ``haproxy.frontend.<frontend>.error_requests``, number of error requests.
* ``haproxy.frontend.<frontend>.response_1xx``, number of HTTP responses with 1xx code.
* ``haproxy.frontend.<frontend>.response_2xx``, number of HTTP responses with 2xx code.
* ``haproxy.frontend.<frontend>.response_3xx``, number of HTTP responses with 3xx code.
* ``haproxy.frontend.<frontend>.response_4xx``, number of HTTP responses with 4xx code.
* ``haproxy.frontend.<frontend>.response_5xx``, number of HTTP responses with 5xx code.
* ``haproxy.frontend.<frontend>.response_other``, number of HTTP responses with other code.
* ``haproxy.frontend.<frontend>.session_current``, number of current sessions.
* ``haproxy.frontend.<frontend>.session_total``, cumulative of total number of session.
* ``haproxy.frontend.bytes_in``, total number of bytes received by all frontends.
* ``haproxy.frontend.bytes_out``, total number of bytes transmitted by all frontends.
* ``haproxy.frontend.session_current``, total number of current sessions for all frontends.


Backends
^^^^^^^^

Metrics per backends:

* ``haproxy.backend.<backend>.bytes_in``, number of bytes received by the backend.
* ``haproxy.backend.<backend>.bytes_out``, number of bytes transmitted by the backend.
* ``haproxy.backend.<backend>.denied_requests``, number of denied requests.
* ``haproxy.backend.<backend>.denied_responses``, number of denied responses.
* ``haproxy.backend.<backend>.downtime``, total downtime in second.
* ``haproxy.backend.<backend>.error_connection``, number of error connections.
* ``haproxy.backend.<backend>.error_responses``, number of error responses.
* ``haproxy.backend.<backend>.queue_current``, number of requests in queue.
* ``haproxy.backend.<backend>.redistributed``, number of times a request was redispatched to another server.
* ``haproxy.backend.<backend>.response_1xx``, number of HTTP responses with 1xx code.
* ``haproxy.backend.<backend>.response_2xx``, number of HTTP responses with 2xx code.
* ``haproxy.backend.<backend>.response_3xx``, number of HTTP responses with 3xx code.
* ``haproxy.backend.<backend>.response_4xx``, number of HTTP responses with 4xx code.
* ``haproxy.backend.<backend>.response_5xx``, number of HTTP responses with 5xx code.
* ``haproxy.backend.<backend>.response_other``, number of HTTP responses with other code.
* ``haproxy.backend.<backend>.retries``, number of times a connection to a server was retried.
* ``haproxy.backend.<backend>.session_current``, number of current sessions.
* ``haproxy.backend.<backend>.session_total``, cumulative number of sessions.
* ``haproxy.backend.bytes_in``, total number of bytes received by all backends.
* ``haproxy.backend.bytes_out``, total number of bytes transmitted by all backends.
* ``haproxy.backend.queue_current``, total number of requests in queue for all backends.
* ``haproxy.backend.session_current``, total number of current sessions for all backends.
* ``haproxy.backend.error_responses``, total number of error responses for all backends.

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

