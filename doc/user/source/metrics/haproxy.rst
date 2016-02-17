.. _haproxy_metrics:

``frontend`` and ``backend`` field values can be:

* cinder-api
* glance-api
* glance-registry-api
* heat-api
* heat-cfn-api
* heat-cloudwatch-api
* horizon-web (when Horizon is deployed without TLS)
* horizon-https (when Horizon is deployed with TLS)
* keystone-public-api
* keystone-admin-api
* mysqld-tcp
* murano-api
* neutron-api
* nova-api
* nova-ec2-api
* nova-metadata-api
* nova-novncproxy-websocket
* sahara-api
* swift-api

Server
^^^^^^

* ``haproxy_connections``, the number of current connections.
* ``haproxy_ssl_connections``, the number of current SSL connections.
* ``haproxy_pipes_free``, the number of free pipes.
* ``haproxy_pipes_used``, the number of used pipes.
* ``haproxy_run_queue``, the number of connections waiting in the queue.
* ``haproxy_tasks``, the number of tasks.
* ``haproxy_uptime``, the HAProxy server uptime in seconds.

Frontends
^^^^^^^^^

* ``haproxy_frontend_bytes_in``, the total number of bytes received by all frontends.
* ``haproxy_frontend_bytes_out``, the total number of bytes transmitted by all frontends.
* ``haproxy_frontend_session_current``, the total number of current sessions for all frontends.

The following metrics have a ``frontend`` field that contains the name of the frontend server.

* ``haproxy_frontend_bytes_in``, the number of bytes received by the frontend.
* ``haproxy_frontend_bytes_out``, the number of bytes transmitted by the frontend.
* ``haproxy_frontend_denied_requests``, the number of denied requests.
* ``haproxy_frontend_denied_responses``, the number of denied responses.
* ``haproxy_frontend_error_requests``, the number of error requests.
* ``haproxy_frontend_response_1xx``, the number of HTTP responses with 1xx code.
* ``haproxy_frontend_response_2xx``, the number of HTTP responses with 2xx code.
* ``haproxy_frontend_response_3xx``, the number of HTTP responses with 3xx code.
* ``haproxy_frontend_response_4xx``, the number of HTTP responses with 4xx code.
* ``haproxy_frontend_response_5xx``, the number of HTTP responses with 5xx code.
* ``haproxy_frontend_response_other``, the number of HTTP responses with other code.
* ``haproxy_frontend_session_current``, the number of current sessions.
* ``haproxy_frontend_session_total``, the cumulative number of sessions.

Backends
^^^^^^^^
.. _haproxy_backend_metric:

* ``haproxy_backend_bytes_in``, the total number of bytes received by all backends.
* ``haproxy_backend_bytes_out``, the total number of bytes transmitted by all backends.
* ``haproxy_backend_queue_current``, the total number of requests in queue for all backends.
* ``haproxy_backend_session_current``, the total number of current sessions for all backends.
* ``haproxy_backend_error_responses``, the total number of error responses for all backends.

The following metrics have a ``backend`` field that contains the name of the backend server.

* ``haproxy_backend_bytes_in``, the number of bytes received by the backend.
* ``haproxy_backend_bytes_out``, the number of bytes transmitted by the backend.
* ``haproxy_backend_denied_requests``, the number of denied requests.
* ``haproxy_backend_denied_responses``, the number of denied responses.
* ``haproxy_backend_downtime``, the total downtime in second.
* ``haproxy_backend_status``, the global backend status where values ``0`` and ``1`` represent respectively ``DOWN`` (all backends are down) and ``UP`` (at least one backend is up).
* ``haproxy_backend_error_connection``, the number of error connections.
* ``haproxy_backend_error_responses``, the number of error responses.
* ``haproxy_backend_queue_current``, the number of requests in queue.
* ``haproxy_backend_redistributed``, the number of times a request was redispatched to another server.
* ``haproxy_backend_response_1xx``, the number of HTTP responses with 1xx code.
* ``haproxy_backend_response_2xx``, the number of HTTP responses with 2xx code.
* ``haproxy_backend_response_3xx``, the number of HTTP responses with 3xx code.
* ``haproxy_backend_response_4xx``, the number of HTTP responses with 4xx code.
* ``haproxy_backend_response_5xx``, the number of HTTP responses with 5xx code.
* ``haproxy_backend_response_other``, the number of HTTP responses with other code.
* ``haproxy_backend_retries``, the number of times a connection to a server was retried.
* ``haproxy_backend_servers``, the count of servers grouped by state. This metric has an additional ``state`` field that contains the state of the backends (either 'down' or 'up').
* ``haproxy_backend_session_current``, the number of current sessions.
* ``haproxy_backend_session_total``, the cumulative number of sessions.
