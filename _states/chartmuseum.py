import os
from salt.exceptions import CommandExecutionError

def __virtual__():
  return 'chartmuseum.get_chart_definition' in __salt__ and 'helm.package' in __salt__

def packages_are_missing(name, chart_path, directories = ["/tmp/charts/packages"]):
  '''
  Package the specified chart into a temporary package directory, temporarily
  renaming the chart definition's parent folder if needed for the Helm package
  manger (see https://github.com/kubernetes/helm/issues/1979 for details).

  name
    The state name

  chart_path
      The full local path on the minion to the chart definition. Note that the
      chart definition's directory does not need to match the `name` value in
      the chart's `Chart.yaml` meta file, despite the corresponding Helm limit:

      see: https://github.com/kubernetes/helm/issues/1979
  
  directorie : [/tmp/charts/packages/]
      The full local path on the minion for all directories in which the chart
      package should exist. The directory must already exist.
  '''
  ret = {'name': chart_path,
         'changes': {},
         'result': True,
         'comment': '' }
  chart_definition = __salt__['chartmuseum.get_chart_definition'](chart_path)
  if chart_definition is None:
    ret['result'] = False
    ret['comment'] = "No or invalid chart definition found at %s" % chart_path
    return ret
  
  package_name = "%s-%s.tgz" % (chart_definition['name'], chart_definition['version'])
  for path in directories:
    if not os.path.exists(os.path.join(path, package_name)):
      ret['changes'][path] = "%s does not contain %s" % (path, package_name) 
  
  return ret


def chart_dependencies_installed(name, chart_path, **kwargs):
  '''
  Install the dependencies for the chart located at the specified chart_path.

  chart_path
      The path to the chart for which to install dependencies
  '''
  ret = { 'name': chart_path,
          'changes': {},
          'result': True,
          'comment': 'Successfully installed dependencies'}
  
  try:
    result = __salt__['helm.install_chart_dependencies'](chart_path, **kwargs)
    ret['comment'] = "Executed command: %s" % result['cmd']
    if result['stdout']:
      ret['changes'].update({ 'stdout': result['stdout'] })
    return ret
  except CommandExecutionError as e:
    ret['result'] = False
    ret['comment'] = ('Failed to install dependencies: %s' % e.error +
                     '\nExecuted command: %s' % e.cmd)

    return ret


def packaged(name, chart_path, destination="/tmp/charts/packages/", **kwargs):
  '''
  Package the specified chart into a temporary package directory, temporarily
  renaming the chart definition's parent folder if needed for the Helm package
  manger (see https://github.com/kubernetes/helm/issues/1979 for details).

  name
    The state name

  chart_path
      The full local path on the minion to the chart definition. Note that the
      chart definition's directory does not need to match the `name` value in
      the chart's `Chart.yaml` meta file, despite the corresponding Helm limit:

      see: https://github.com/kubernetes/helm/issues/1979
  
  destination : /tmp/charts/packages/
      The full local path on the minion for the directory to which the generated 
      Helm chart package should be output. The directory must already exist.
  '''
  ret = {'name': chart_path,
         'changes': {},
         'result': None,
         'comment': '' }
  chart_definition = __salt__['chartmuseum.get_chart_definition'](chart_path)
  if chart_definition is None:
    ret['result'] = False
    ret['comment'] = "No or invalid chart definition found at %s" % chart_path
    return ret

  #
  # Helm package currently requires the chart's parent directory name to match
  # the Chart.yaml's configured name. If it doesn't, the package execution fails
  # to run. Since there's an open issue to remove this restriction and this 
  # imposes weird constraints on how the chart is structured, workaround this 
  # behavior for now.
  # 
  # see: https://github.com/kubernetes/helm/issues/1979
  # 
  # TODO: remove me when this is no longer necessary!
  chart_expected_path=os.path.join(os.path.dirname(chart_path), chart_definition['name'])
  if chart_expected_path != chart_path:
    __salt__['cmd.shell']('mv %s %s' % (chart_path, chart_expected_path))

  try:
    package_result = __salt__['helm.package'](
      chart_expected_path,
      destination=destination,
      **kwargs
    )

    ret['result'] = True
    ret['comment'] = "Executed command: %s" % package_result['cmd']
    ret['changes'].update({ 
      'name': chart_definition['name'],
      'version': chart_definition['version'],
      'output': package_result['stdout']
    })
  except CommandExecutionError as e:
    ret['result'] = False
    ret['comment'] = ("Failed to package chart: %s" % e.error +
                     "\nExecuted command: %s" % e.cmd)
    return ret
  finally:
    #
    # TODO: remove me when this is no longer necessary!
    #
    if chart_expected_path != chart_path:
      __salt__['cmd.shell']('mv %s %s' % (chart_expected_path, chart_path))
  return ret
