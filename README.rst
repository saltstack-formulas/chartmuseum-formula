===================
chartmuseum-formula
===================

.. image:: https://travis-ci.org/saltstack-formulas/chartmuseum-formula.svg?branch=master
    :target: https://travis-ci.org/saltstack-formulas/chartmuseum-formula

A Salt formula to manage a Chartmuseum (Kubernetes Helm chart repository) 
installation on the target minion, including keeping the served charts 
up-to-date with a remote or local chart definition github repository.

Pre-requisites
==============

The target minion must have:

* docker installed; and
* docker-py available to the Salt minion service (*note that the salt-minion 
  service requires a restart after installation of docker-py to a minion*).

If any chart repositories are configured under the ``chartmuseum:git:repos`` 
key, the target minion must additionally have:

* the `helm-formula <https://github.com/tmeneau/salt-formula-helm/tree/stable>`_ 
  available, including at minimum the following configuration:

.. code-block:: yaml
  
  helm:
    tiller:
      install: false
    kubectl:
      install: false
    #
    # any repositories that need to be available for installing chart 
    # dependencies can be configured with the helm client here. When this is
    # required, packaging the chart will fail with an error indicating a
    # repository could not be reached.
    #
    repos:
      {{ repo_name }}: {{ repo_url }}
      ...

OS Compatibility
================

Tested with:

* Ubuntu 14.04 LTS

Available States
================

.. contents::
    :local:

``data_dir_present``
--------------------

Ensures the requisite data directories exist in the desired state on the target 
minion.

``removed``
-----------

Ensures any trace of the Chartmuseum docker contaienr is removed from the target 
host. This includes:

* stopping and removing the running container
* ensuring the data directory is removed and unmounted (as applicable)
* ensuring the Chartmuseum docker image is absent from the target minion

``running``
-----------

Ensures the Chartmuseum docker container is running on the target minion with 
the appropriate configuration parameters. This state will:

1. ensure the configured data directory exists and is mounted (as applicable)
2. ensure the configured Chartmuseum docker image version is available on the 
  minion
3. ensure the Chartmuseum docker container is running with the proper image 
  version and configuration parameters.

**includes**:

* `data_dir_present`_
* `packages_updated`_

``packages_updated``
--------------------

A very helpful state that:

1. ensures any configured chart definition github repositories are up-to-date 
  with the remote or local source repository;
2. installs any dependencies required for the chart; and
3. packages the chart into the mounted Chartmuseum container's served chart 
  directory.

Availale Modules
===============

To view documentation on the available modules, run: 

.. code-block:: shell
  
  salt '{{ tgt }}' sys.doc chartmuseum

Sample Pillar
==============

See the `pillar.example <pillar.example>`_ for a documented example pillar file.

Contributions
=============

Contributions are always welcome. The main development guidelines include:

* write clean code (proper YAML+Jinja syntax, no trailing whitespaces, no empty 
  lines with whitespaces
* set sane default settings
* test your code
* update README.rst doc

Testing
=======

Running the tests requires a couple local pre-requisites:

* a recent version of Ruby (with Bundler installed);
* Docker installed (including docker-compose)

Running the tests:

.. code-block:: shell

  bundle
  bundle exec rake verify

Be sure to destroy the test VMs when you're done testing to liberate your local
development resources:

.. code-block:: shell

  bundle exec rake destroy
