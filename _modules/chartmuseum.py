import logging
import yaml
import os
import salt
import re

log = logging.getLogger(__name__)

def get_chart_definition(local_chart_path, chart_yaml_file_name='Chart.yaml'):
  '''
  Retrieve the chart metadata from the Chart.yaml file found in the local
  copy of a chart definition.

  local_chart_path
      The full local path on the minion to the chart definition.

  chart_yaml_file_name : Chart.yaml
      The name of the YAML file from which to parse the chart's metadata. Note
      that Helm requires this to be Chart.yaml, so this is unlikely to ever need
      to be specified by consumers.
  '''
  if not os.path.exists(local_chart_path):
    log.error("chart definition not found at path %s" % local_chart_path)
    return None
  
  chart_meta_path = os.path.join(local_chart_path, chart_yaml_file_name)
  log.trace("testing for chart metadata at path: %s" % chart_meta_path)
  if not os.path.exists(chart_meta_path):
    return None
  
  chart_meta_yaml = None

  try:
    with open(chart_meta_path) as chart_meta_stream:
      chart_meta_yaml = yaml.load(chart_meta_stream)
  except:
    # ignore any error since we'll also catch exceptions for empty Chart.yaml
    # files below
    pass
  
  if chart_meta_yaml is None:
    log.error("Encountered invalid Helm chart metadata in %s" % chart_meta_path)
    return None
  
  log.trace("loaded chart metadata file %s as yaml: %s" % (chart_meta_path, chart_meta_yaml))
  log.debug("loaded chart definition: %s" % chart_meta_yaml)
  
  return chart_meta_yaml


def get_chart_definitions(charts_parent_dir):
  '''
  Retrieve the chart metadata from all chart definitions located immediately
  within the specified parent directory. Note that the logic for determining
  whether a child directory is a chart definition is to simply check for a valid
  `Chart.yaml` file within the child directory.

  charts_parent_dir
      The parent directory within which to extract a list of contained chart
      definitions
  '''
  definitions = []
  
  #
  # don't fail if the parent doesn't exist, but log an error for easier 
  # debugging
  #
  if not os.path.exists(local_repos_parent):
    log.error("chart definition parent folder doesn't exist at path %s" % local_repos_parent)
    return definitions
  
  for repo in os.listdir(local_repos_parent):
    definition = get_chart_definition(os.path.join(local_repos_parent, repo))
    if definition is not None:
      definitions.append(definition)
  
  log.trace("loaded definitions: %s" % definitions)
  return definitions

def get_repo_coordinates(repo_source, target_base, subpath = None):
  last_dir_matcher = r'.*\/([^\/]*)'
  repo_name_match = re.match(last_dir_matcher, repo_source)
  if not repo_name_match:
    return {}

  repo_name = repo_name_match.group(1).replace(".git", "")
  chart_name = repo_name
  if subpath:
    chart_name_match = re.match(last_dir_matcher, subpath)
    if chart_name_match:
      chart_name = chart_name_match.group(1)

  chart_path = target_base
  chart_path += "/" + (repo_name if subpath is None else repo_name + "/" + subpath)
  result = {
    "repo_source": repo_source,
    "repo_name": repo_name_match.group(1).replace(".git", "") if repo_name_match else None,
    "repo_target": target_base + "/" + repo_name,
    "chart_path": chart_path,
    "chart_name": chart_name
  }
  return result