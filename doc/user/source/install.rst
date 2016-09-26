.. _user_installation:

Install using the RPM file of the Fuel plugins catalog
------------------------------------------------------

**To install the StackLight Collector Fuel plugin using the RPM file of the Fuel
plugins catalog:**

#. Go to the `Fuel plugins catalog <https://www.mirantis.com/validated-solution-integrations/fuel-plugins/>`_.
#. From the :guilabel:`Filter` drop-down menu, select the Mirantis OpenStack
   version you are using and the :guilabel:`Monitoring` category.
#. Download the RPM file.

#. Copy the RPM file to the Fuel Master node:

   .. code-block:: console

      [root@home ~]# scp lma_collector-0.10-0.10.2-1.noarch.rpm \
      root@<Fuel Master node IP address>:

#. Install the plugin using the
   `Fuel Plugins CLI <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/cli/cli_plugins.html>`_:

   .. code-block:: console

      [root@fuel ~]# fuel plugins --install lma_collector-0.10-0.10.2-1.noarch.rpm

#. Verify that the plugin is installed correctly:

   .. code-block:: console

      [root@fuel ~]# fuel plugins --list
      id | name                 | version  | package_version
      ---|----------------------|----------|----------------
      1  | lma_collector        | 0.10.2   | 4.0.0


Install from source
-------------------

Alternatively, you may want to build the plugin RPM file from source if, for
example, you want to test the latest features of the master branch or
customize the plugin.

.. note:: Running a Fuel plugin that you built yourself is at your own risk
   and will not be supported.

To install the StackLight Collector Plugin from source, first prepare an
environment to build the RPM file. The recommended approach is to build the
RPM file directly onto the Fuel Master node so that you will not have to copy
that file later on.

**To prepare an environment and build the plugin:**

#. Install the standard Linux development tools:

   .. code-block:: console

      [root@home ~] yum install createrepo rpm rpm-build dpkg-devel

#. Install the Fuel Plugin Builder. To do that, you should first get pip:

   .. code-block:: console

      [root@home ~] easy_install pip

#. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip`:

   .. code-block:: console

      [root@home ~] pip install fuel-plugin-builder

   .. note:: You may also need to build the Fuel Plugin Builder if the package
      version of the plugin is higher than the package version supported by the
      Fuel Plugin Builder you get from ``pypi``. For instructions on how to
      build the Fuel Plugin Builder, see the *Install Fuel Plugin Builder*
      section of the `Fuel Plugin SDK Guide <http://docs.openstack.org/developer/fuel-docs/plugindocs/fuel-plugin-sdk-guide/create-plugin/install-plugin-builder.html>`_.

#. Clone the plugin repository:

   .. code-block:: console

      [root@home ~] git clone https://github.com/openstack/fuel-plugin-lma-collector.git

#. Verify that the plugin is valid:

   .. code-block:: console

      [root@home ~] fpb --check ./fuel-plugin-lma-collector

#.  Build the plugin:

    .. code-block:: console

       [root@home ~] fpb --build ./fuel-plugin-lma-collector

**To install the plugin:**

#. Once you create the RPM file, install the plugin:

   .. code-block:: console

      [root@fuel ~] fuel plugins --install ./fuel-plugin-lma-collector/*.noarch.rpm

#. Verify that the plugin is installed correctly:

   .. code-block:: console

      [root@fuel ~]# fuel plugins --list
      id | name                 | version  | package_version
      ---|----------------------|----------|----------------
      1  | lma_collector        | 0.10.2   | 4.0.0
