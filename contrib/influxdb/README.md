# Description

Scripts and tools for running an InfluxDB server to be used with the LMA
toolchain.

# Running

Simply:

```
$ run_container.sh
```

Use environment variables to override the default configuration:

```
$ LISTEN_ADDRESS=192.169.0.1 run_container.sh
```

Supported environment variables for configuration:

* LISTEN_ADDRESS: listen address on the container host (default=127.0.0.1)

* LMA_DB: name of the LMA database (default=lma)

* LMA_USER: username for the LMA db (default=lma)

* LMA_PASSWORD: password for the LMA user (default=lmapass)

* ROOT_PASSWORD: password for the admin user (default=supersecret)
