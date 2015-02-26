# Description

Scripts and tools for running an ElasticSearch server to be used with the LMA
collector.

# Requirements

To run ElasticSearch, the host should have at least 1GB of free RAM. You also
need sufficient free disk space for storing the data. The exact amount of disk
depends highly on your environment and retention policy but 20GB is probably a
sane minimum.

To store and query the data, clients need to be able to connect to the IP
address of the container's host on the TCP port 9200.

# Running

Simply:

```
$ ./run_container.sh
```

Use environment variables to override the default configuration:

```
$ ES_MEMORY=2 ./run_container.sh
```

Supported environment variables for configuration:

* ES_LISTEN_ADDRESS: listen address on the container host (default=127.0.0.1)

* ES_DATA: directory where to store the ES data and logs (default=~/es_volume)

* ES_MEMORY: amount of memory (in GB) allocated to the JVM (default=16)

# Testing

You can check that ElasticSearch is working using `curl`:

```
curl http://$HOST:9200/
```

Where `HOST` is the IP address or the name of the container's host.

The expected output is something like this:

```
{
  "status" : 200,
  "name" : "fuel.domain.tld",
  "cluster_name" : "elasticsearch",
  "version" : {
    "number" : "1.4.2",
    "build_hash" : "927caff6f05403e936c20bf4529f144f0c89fd8c",
    "build_timestamp" : "2014-12-16T14:11:12Z",
    "build_snapshot" : false,
    "lucene_version" : "4.10.2"
  },
  "tagline" : "You Know, for Search"
}
```
