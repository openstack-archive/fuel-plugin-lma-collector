Running tests
-------------

You need to have `tox` and `bundler` installed for running the tests.

Quickstart for Ubuntu Trusty::

    apt-get install tox ruby ruby1.9.1-dev
    gem install bundler
    tox

For `tox` to run the Lua unit tests included in the ``lma_collector`` Puppet
module additional system packages are required::

    apt-get install cmake lua5.1 liblua5.1 liblua5.1-dev lua-cjson lua-unit
