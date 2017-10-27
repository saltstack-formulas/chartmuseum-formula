# Chartmuseum Formula

A Salt formula to manage a Chartmuseum (Kubernetes Helm chart repository) installation on the target minion, including keeping the served charts up-to-date with a remote or local chart definition github repository.

### Pre-requisites

The target minion must have:

* docker installed; and
* docker-py available to the Salt minion service (_note that the salt-minion service requires a restart after installation of docker-py to a minion_).

If any chart repositories are configured under the `chartmuseum:git:repos` key,
the target minion must additionally have:

* the [salt-formula-helm](https://github.com/tmeneau/salt-formula-helm/tree/stable) formula available, including at minimum the following configuration:

```yaml
helm:
  tiller:
    install: false
  kubectl:
    install: false
  #
  # any repositories that need to be available for installing chart 
  # dependencies can be configured with the helm client here
  #
  repos:
    {{ repo_name }}: {{ repo_url }}
    ...
```

### Available States

#### `chartmuseum.data_dir_present`

Ensures the requisite data directories exist in the desired state on the target minion

#### `chartmuseum.removed`

Ensures any trace of the Chartmuseum docker contaienr is removed from the target host. This includes:

* stopping and removing the running container
* ensuring the data directory is removed and unmounted (as applicable)
* ensuring the Chartmuseum docker image is absent from the target minion

#### `chartmuseum.running`

Ensures the Chartmuseum docker container is running on the target minion with the appropriate configuration parameters. This state will:

1. ensure the configured data directory exists and is mounted (as applicable)
2. ensure the configured Chartmuseum docker image version is available on the minion
3. ensure the Chartmuseum docker container is running with the proper image version and configuration parameters.

**includes**:
* `chartmuseum.data_dir_present`
* `chartmuseum.packages_updated`

#### `chartmuseum.packages_updated`

A very helpful state that:

1. ensures any configured chart definition github repositories are up-to-date with the remote or local source repository;
2. installs any dependencies required for the chart; and
3. packages the chart into the mounted Chartmuseum container's served chart directory.