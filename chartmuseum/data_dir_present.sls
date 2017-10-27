{% from slspath + "/map.jinja" import config, constants with context %}

#
# Create the required datadir
#
chartmuseum-data-dir-present:
  file.directory:
    - name: {{ config['data_dir'] }}/public
    - makedirs: True

#
# If a datavolume was specified, mount the volume and format
# the device if necessary
#
{% if config['data_volume'] %}
chartmuseum-data-volume-formatted:
  blockdev.formatted:
    - name: {{ config['data_volume'].device }}
    - fs_type: {{ config['data_volume'].fstype }}

chartmuseum-data-volume-mounted:
  mount.mounted:
    - require:
      - file: chartmuseum-data-dir-present
      - blockdev: chartmuseum-data-volume-formatted
    - name: {{ config['data_dir'] }}
    - device: {{ config['data_volume'].device }}
    - fstype: {{ config['data_volume'].fstype }}
    - persist: False
{% endif %}


{{ constants.git_repos_dir }}:
  file.directory:
    - makedirs: True
    - recurse:
      - mode

{{ constants.public_repo_dir }}:
  file.directory:
    - makedirs: True
    - recurse:
      - mode