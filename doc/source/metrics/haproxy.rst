.. _HAproxy_metrics:

Server
^^^^^^

* ``haproxy.connections.gauge``, Number of current connections.
* ``haproxy.ssl.connections.gauge``, Number of current SSL connections.
* ``haproxy.run_queue.gauge``, Number of connections waiting in the queue.
* ``haproxy.tasks.gauge``, Number of tasks.
* ``haproxy.uptime_seconds.counter``, Derivative of HAproxy server uptime in seconds.

Frontends
^^^^^^^^^

Metrics per frontend:

* ``haproxy.frontend.<frontend>.bytes_in.derive``, Bytes in.
* ``haproxy.frontend.<frontend>.bytes_out.derive``, Bytes out.
* ``haproxy.frontend.<frontend>.denied_request.derive``, Number of denied requests.
* ``haproxy.frontend.<frontend>.denied_response.derive``, Number of denied responses.
* ``haproxy.frontend.<frontend>.error_request.derive``, Number of error requests.
* ``haproxy.frontend.<frontend>.request_rate.gauge``,  HTTP requests per second over last elapsed second.
* ``haproxy.frontend.<frontend>.response_1xx.derive``, Number of HTTP responses with 1xx code.
* ``haproxy.frontend.<frontend>.response_2xx.derive``, Number of HTTP responses with 2xx code.
* ``haproxy.frontend.<frontend>.response_3xx.derive``, Number of HTTP responses with 3xx code.
* ``haproxy.frontend.<frontend>.response_4xx.derive``, Number of HTTP responses with 4xx code.
* ``haproxy.frontend.<frontend>.response_5xx.derive``, Number of HTTP responses with 5xx code.
* ``haproxy.frontend.<frontend>.response_other.derive``, Number of HTTP responses with other code.
* ``haproxy.frontend.<frontend>.session_current.gauge``, Number of current sessions.
* ``haproxy.frontend.<frontend>.session_rate.gauge``, Number of sessions per second over last elapsed second.
* ``haproxy.frontend.<frontend>.session_total.counter``, Derivative of total number of connections.


Bakends
^^^^^^^

Metrics per backends:

* ``haproxy.backend.<backend>.bytes_in.derive``, Bytes in.
* ``haproxy.backend.<backend>.bytes_out.derive``, Bytes out.
* ``haproxy.backend.<backend>.denied_request.derive``, Number of denied requests.
* ``haproxy.backend.<backend>.denied_response.derive``, Number of denied responses.
* ``haproxy.backend.<backend>.downtime.counter``, Derivative of total downtime in second.
* ``haproxy.backend.<backend>.error_connection.derive``, Number of error connections.
* ``haproxy.backend.<backend>.error_response.derive``, Nmber of error responses.
* ``haproxy.backend.<backend>.queue_current.gauge``, Number of requests in queue.
* ``haproxy.backend.<backend>.redistributed.derive``, Number of times a request was redispatched to another server.
* ``haproxy.backend.<backend>.response_1xx.derive``, Number of HTTP responses with 1xx code.
* ``haproxy.backend.<backend>.response_2xx.derive``, Number of HTTP responses with 2xx code.
* ``haproxy.backend.<backend>.response_3xx.derive``, Number of HTTP responses with 3xx code.
* ``haproxy.backend.<backend>.response_4xx.derive``, Number of HTTP responses with 4xx code.
* ``haproxy.backend.<backend>.response_5xx.derive``, Number of HTTP responses with 5xx code.
* ``haproxy.backend.<backend>.response_other.derive``, Number of HTTP responses with other code.
* ``haproxy.backend.<backend>.retries.counter``, Derivative of number of times a connection to a server was retried.
* ``haproxy.backend.<backend>.session_current.gauge``, Number of current sessions.
* ``haproxy.backend.<backend>.session_rate.gauge``, Number of sessions per second over last elapsed second.
* ``haproxy.backend.<backend>.session_total.counter``, Derivative of total number of connections.

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

