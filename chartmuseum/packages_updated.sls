{% from slspath + "/map.jinja" import config, constants with context %}
{% from "helm/map.jinja" import config as helm_config with context %}

include:
  - .data_dir_present
  - helm.repos_managed

{%- set synced_repos = [] %}
{%- for git_repo in config.get("git", {}).get("repos", []) %}

#
# identify the "coordinates" for the target chart repository, which is either
# the git url and subpath, or just the local file path for the chart definition.
#
{%- set repo_path = git_repo.url if git_repo.get('url') else git_repo.path %}
{%- set repo_coords = salt['chartmuseum.get_repo_coordinates'](
        repo_source = repo_path, 
        target_base = constants.git_repos_dir,
        subpath = git_repo.get('subpath')
    ) %}

#
# Avoid checking git state redundantly if the source repository has already 
# been synchronized (as might be the case if multiple chart definitions are 
# included in a single github repository)
#
{%- if git_repo.get('url') %}

#
# ensure the git repository is up to date with the desired branch, tag, or 
# commit ID so long as it hasn't already been synchronized
#
{%- if not git_repo.url in synced_repos %}
{{ repo_coords.repo_source }}_repository-present:
  git.latest:
    - name: {{ git_repo.url }}
    - target: {{ repo_coords.repo_target }}
    {% if 'branch' in git_repo %}
    - branch: {{ git_repo.branch }}
    {% endif %}
    {% if 'rev' in git_repo %}
    - rev: {{ git_repo.rev }}
    {% endif %}
  
  {%- do synced_repos.append(repo_coords.repo_source) %}
{%- endif %} #not git_repo.url in synced_repos

{%- elif git_repo.get("path") %}
{{ repo_coords.repo_source }}_repository-present:
  file.copy:
    - name: {{ repo_coords.repo_target }}
    - source: {{ repo_coords.repo_source }}
    - force: True

  {%- do synced_repos.append(repo_coords.repo_source) %}
{%- else %}
"A helm chart repository is incorrectly configured in the pillar; must have `url` or `path`":
  test.fail_without_changes
{%- continue %}

{%- endif %}

{{ repo_coords.chart_name }}_package_existence_checked:
  chartmuseum.packages_are_missing:
    - require:
      - {{ repo_coords.repo_source }}_repository-present
    - chart_path: {{ repo_coords.chart_path }}
    - directories: 
      - {{ constants.public_repo_dir }}

{{ repo_coords.chart_name }}_dependencies-installed:
  chartmuseum.chart_dependencies_installed:
    - chart_path: {{ repo_coords.chart_path }}
    - helm_home: {{ helm_config.helm_home }}
    - require:
      - {{ repo_coords.repo_source }}_repository-present
      - {{ repo_coords.chart_name }}_package_existence_checked
    {% if not config.get('force_repackage') -%}
    - onchanges:
      - {{ repo_coords.repo_source }}_repository-present
      - {{ repo_coords.chart_name }}_package_existence_checked
    {%- endif %}
    - onlyif:
      - test -e {{ repo_coords.chart_path }}/requirements.yaml

helm-chart-packaged_{{ repo_coords.chart_name }}:
  chartmuseum.packaged:
    - chart_path: {{ repo_coords.chart_path }}
    - destination: {{ constants.public_repo_dir }}
    - helm_home: {{ helm_config.helm_home }}
    {% if not config.get('force_repackage') -%}
    - onchanges: 
      - {{ repo_coords.repo_source }}_repository-present
      - {{ repo_coords.chart_name }}_package_existence_checked
      - {{ repo_coords.chart_name }}_dependencies-installed
    {% else %}
    - require:
      - {{ repo_coords.repo_source }}_repository-present
      - {{ repo_coords.chart_name }}_dependencies-installed
    {%- endif %}

{%- endfor %}