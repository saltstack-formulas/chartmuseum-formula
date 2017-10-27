{% from slspath + "/map.jinja" import config, constants with context %}

include:
  - .data_dir_present
  - helm.repos_managed

{%- for git_repo in config.get("git", {}).get("repos", []) %}

{%- set coordinates = git_repo.url if git_repo.get('url') else git_repo.path %}
{%- set parsed_repo_name = salt['chartmuseum.get_repo_name'](coordinates) %}

{%- if git_repo.get('url') %}
#
# ensure the git repository is up to date with the desired branch, tag, or 
# commit ID
#
{{ parsed_repo_name }}_repository-present:
  git.latest:
    - name: {{ git_repo.url }}
    - target: {{ constants.git_repos_dir }}/{{ parsed_repo_name }}
    {% if 'branch' in git_repo %}
    - branch: {{ git_repo.branch }}
    {% endif %}
    {% if 'rev' in git_repo %}
    - rev: {{ git_repo.rev }}
    {% endif %}

{%- elif 'path' in git_repo %}
{{ parsed_repo_name }}_repository-present:
  file.copy:
    - name: {{ constants.git_repos_dir }}/{{ parsed_repo_name }}
    - source: {{ git_repo.path }}
    - force: True

{%- else %}
"A helm chart repository is incorrectly configured in the pillar; must have `url` or `path`":
  test.fail_without_changes
{%- continue %}

{%- endif %}

{{ parsed_repo_name }}_package_existence_checked:
  chartmuseum.packages_are_missing:
    - require:
      - {{ parsed_repo_name }}_repository-present
    - chart_path: {{ constants.git_repos_dir }}/{{ parsed_repo_name }}
    - directories: 
      - {{ constants.public_repo_dir }}

{{ parsed_repo_name }}_dependencies-installed:
  chartmuseum.chart_dependencies_installed:
    - chart_path: {{ constants.git_repos_dir }}/{{ parsed_repo_name }}
    {%- if config.get('helm_home') %}
    - helm_home: {{ config['helm_home'] }}
    {%- endif %}
    - require:
      - {{ parsed_repo_name }}_repository-present
      - {{ parsed_repo_name }}_package_existence_checked
    {% if not config.get('force_repackage') -%}
    - onchanges:
      - {{ parsed_repo_name }}_repository-present
      - {{ parsed_repo_name }}_package_existence_checked
    {%- endif %}
    - onlyif:
      - test -e {{ constants.git_repos_dir }}/{{ parsed_repo_name }}/requirements.yaml

helm-chart-packaged_{{ parsed_repo_name }}:
  chartmuseum.packaged:
    - chart_path: {{ constants.git_repos_dir }}/{{ parsed_repo_name }}
    - destination: {{ constants.public_repo_dir }}
    {%- if config.get('helm_home') %}
    - helm_home: {{ config['helm_home'] }}
    {%- endif %}
    {% if not config.get('force_repackage') -%}
    - onchanges: 
      - {{ parsed_repo_name }}_repository-present
      - {{ parsed_repo_name }}_package_existence_checked
      - {{ parsed_repo_name }}_dependencies-installed
    {% else %}
    - require:
      - {{ parsed_repo_name }}_repository-present
      - {{ parsed_repo_name }}_dependencies-installed
    {%- endif %}

{%- endfor %}