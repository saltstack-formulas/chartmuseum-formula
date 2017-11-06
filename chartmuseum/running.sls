{% from slspath + "/map.jinja" import config, constants with context %}

include:
  - .data_dir_present
  - .packages_updated

#
# Ensure the requisite image is present
#
chartmuseum-image-present:
  dockerng.image_present:
    - name: {{ constants['image_name'] + ":" + config['image_version'] }}

chartmuseum-running:
  require:
    - sls: {{ slspath }}.data_dir_present
    - dockerng: chartmuseum-image-present

  dockerng.running:
    - name: {{ constants.container_name }}
    - image: {{ constants.image_name }}:{{ config.image_version }}
    - hostname: {{ config.fqdn }}
    - binds:
      - "{{ constants.volume_bind }}"
    - port_bindings:
      - {{ config['bind_ip'] }}:{{ config['bind_port'] }}:8080
    - cmd:
      - "--port=8080"
      - "--storage=local"
      - "--storage-local-rootdir={{ constants.chartmuseum_local_root_dir }}"
      {% if config.get('debug') %}
      - "--debug"
      {% endif %}
      {% if config.get('public_url') %}
      - "--chart-url={{ config['public_url'] }}"
      {% endif %}
