{% from slspath + "/map.jinja" import config, constants with context %}

chartmuseum-stopped:
  dockerng.stopped:
    - name: {{ constants.container_name }}
    - error_on_absent: False

{% if config['data_volume'] %}
chartmuseum-data-volume-unmounted:
  mount.unmounted:
    - name: {{ config['data_dir'] }}
    - device: {{ config.data_volume.device }}
    - persist: False
    - require_in:
      - file: chartmuseum-data-directory-removed
{% endif %}

chartmuseum-data-directory-removed:
  file.absent:
    - name: {{ config.data_dir }}

chartmuseum-container-removed:
  dockerng.absent:
    - name: {{ constants.container_name }}

chartmuseum-image-absent:
  dockerng.image_absent:
    - name: "{{ constants.image_name }}:{{ config.image_version }}"