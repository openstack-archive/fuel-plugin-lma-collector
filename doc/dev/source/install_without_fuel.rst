Installation without Fuel
=========================

This section provides instructions and hints on how you could deploy the LMA
Collector service without using the Fuel plugin package. For instance, the
Fuel version that you are running isn't compatible with the current release of
the LMA Collector or you want to have a greater control on the configuration of
the LMA Collector.

In such situations, it is possible to leverage directly the Puppet modules and
write your own Puppet manifests to configure and run the LMA Collector service
on your OpenStack nodes.

Pre-requisites
^^^^^^^^^^^^^^

* The nodes are already deployed with the OpenStack services.

* The LMA packages are going to be available from a local repository that you have access to.

* Configuration management is done with Puppet >= 3.x. Both `master and
  masterless methods
  <https://docs.puppetlabs.com/puppet/latest/reference/dirs_manifest.html>`_
  are supported.

* You have already written the main Puppet manifests. You can have a look at the
  `reference documentation
  <https://github.com/openstack/fuel-plugin-lma-collector/tree/master/deployment_scripts/puppet/modules/lma_collector/README.md>`_
  and at the `examples
  <https://github.com/openstack/fuel-plugin-lma-collector/tree/master/deployment_scripts/puppet/modules/lma_collector/examples>`_
  of the `lma_collector` Puppet module.

* The satellite clusters (Elasticsearch/Kibana, InfluxDB/Grafana and Nagios)
  are already deployed and the nodes have access to them.

Download the packages
^^^^^^^^^^^^^^^^^^^^^

Before running the Puppet manifests, you have to make sure that the nodes will
be able to download and install the necessary packages.

This small script will get you started:

.. code-block:: bash

   WORK_DIR=/tmp/lma_collector
   PACKAGES_DIR=${WORK_DIR}/packages
   mkdir -p ${PACKAGES_DIR}
   rm -rf ${PACKAGES_DIR:?}/*
   pushd $WORK_DIR
   git clone https://github.com/openstack/fuel-plugin-lma-collector.git
   cd fuel-plugin-lma-collector
   ./pre_build_hook
   cp ./repositories/ubuntu/*.deb ${PACKAGES_DIR}
   (cd ${PACKAGES_DIR} && dpkg-scanpackages . > Packages)
   echo "The packages directory is available at ${PACKAGES_DIR}"
   popd

Then you should copy the `packages` directory to your local repository server
and update the APT configuration on the deployed nodes accordingly to enable
the new source repository.

Building the Puppet modules
^^^^^^^^^^^^^^^^^^^^^^^^^^^

You have to build locally the `lma_collector` and `heka` Puppet modules because
they aren't yet available from PuppetForge.

.. code-block:: bash

   WORK_DIR=/tmp/lma_collector
   mkdir -p ${WORK_DIR}
   rm -rf ${WORK_DIR:?}/*
   pushd $WORK_DIR
   git clone https://github.com/openstack/fuel-plugin-lma-collector.git
   cd fuel-plugin-lma-collector/deployment_scripts/puppet/modules/
   for module in heka lma_collector
   do
      pushd $module
      puppet module build
      cp pkg/*.tar.gz ${WORK_DIR}
      popd
   done
   echo "The Puppet modules are available at ${WORK_DIR}"
   popd

Installing the Puppet modules
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

After building the `lma_collector` and `heka` Puppet modules, you need to
install them on your Puppet master or on all the nodes (in case of masterless
installation).

.. code-block:: bash

   puppet module install mirantis-heka-1.0.0.tar.gz
   puppet module install mirantis-lma_collector-1.0.0.tar.gz

Running the main Puppet manifest(s)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Finally you can run your main Puppet manifest(s). For the masterless case and
assuming, it would mean executing the `puppet apply` command similar to this
snippet:

.. code-block:: bash

   puppet apply /etc/puppet/manifests/
