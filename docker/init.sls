{% from "docker/map.jinja" import docker with context %}
{% if docker.kernel is defined %}
include:
  - .kernel
{% endif %}

docker package dependencies:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - iptables
      - ca-certificates
      - lxc
      - python-apt

purge old packages:
  pkgrepo.absent:
    - name:
      - deb https://get.docker.com/ubuntu docker main
      - deb http://http.debian.net/debian jessie-backports main
  pkg.purged:
    - name: lxc-docker*
    - require_in:
      - pkgrepo: docker package repository

docker package repository:
  pkgrepo.managed:
    - name: deb https://apt.dockerproject.org/repo {{ grains["os"]|lower }}-{{ grains["oscodename"] }} main
    - humanname: {{ grains["os"] }} {{ grains["oscodename"]|capitalize }} Docker Package Repository
    - keyid: 58118E89F3A912897C070ADBF76221572C52609D
    - keyserver: keyserver.ubuntu.com
    - file: /etc/apt/sources.list.d/docker.list
    - refresh_db: True
    - require_in:
      - pkg: docker package
    - require:
      - pkg: docker package dependencies

docker package:
  {%- if "version" in docker %}
  pkg.installed:
    - name: docker-engine
    - version: {{ docker.version }}
  {%- else %}
  pkg.latest:
    - name: docker-engine
  {%- endif %}
    - refresh: {{ docker.refresh_repo }}
    - require:
      - pkg: docker package dependencies
      - pkgrepo: docker package repository
      - file: docker-config

docker-config:
  file.managed:
    - name: /etc/default/docker
    - source: salt://docker/files/config
    - template: jinja
    - mode: 644
    - user: root

docker-service:
  service.running:
    - name: docker
    - enable: True
    - watch:
      - file: /etc/default/docker
      - pkg: docker package
    {% if "process_signature" in docker %}
    - sig: {{ docker.process_signature }}
    {% endif %}


{% if docker.install_docker_py %}
docker-py requirements:
  pkg.installed:
    - name: python-pip
  pip.installed:
    - name: pip
    - upgrade: True

docker-py:
  pip.installed:
    {%- if "pip_version" in docker %}
    - name: docker-py {{ docker.pip_version }}
    {%- else %}
    - name: docker-py
    {%- endif %}
    - require:
      - pkg: docker package
      - pip: docker-py requirements
    - reload_modules: True
{% endif %}
