#!/bin/bash

cd /home/ubuntu
mkdir test
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py --break-system-packages
sudo python3 -m pip install ansible --break-system-packages
sudo apt install -y git ansible-core
tee -a hosts.yml >/dev/null <<EOT
terraform-ansible:
 hosts:
  localhost:
   ansible_connection: local
 vars:
  ansible_user: ubuntu
EOT
tee -a playbook.yml >/dev/null <<EOT
- hosts: terraform-ansible
  become: true
  tasks:
  - name: Install python 3, setuptools and virtualenv
    apt:
      name:
      - python3
      - python3-venv
      - python3-pip
      - python3-setuptools
      update_cache: yes
      state: present

  - name: Remove old project
    file:
      path: "{{ item }}"
      state: absent
    loop:
    - /home/ubuntu/test
    ignore_errors: true
    become_user: ubuntu

  - name: Git Clone
    ansible.builtin.git:
      repo: https://github.com/guilhermeonrails/clientes-leo-api.git
      dest: /home/ubuntu/test
      version: master
      clone: yes
      force: yes
    become_user: ubuntu

  - name: Create virtualenv (if not exists)
    command: python3 -m venv /home/ubuntu/venv
    args:
      creates: /home/ubuntu/venv/bin/activate
    become_user: ubuntu

  - name: Upgrade pip inside virtualenv
    command: /home/ubuntu/venv/bin/pip install --upgrade pip
    become_user: ubuntu

  - name: Add new lib to requirements.txt
    shell: 'echo "setuptools==80.9.0" >> /home/ubuntu/test/requirements.txt'
    become_user: ubuntu

  - name: Install Python requirements into virtualenv
    ansible.builtin.pip:
      virtualenv: /home/ubuntu/venv
      requirements: /home/ubuntu/test/requirements.txt
      state: forcereinstall
    become_user: ubuntu

  - name: Ensure ALLOWED_HOSTS contains wildcard
    lineinfile:
      path: /home/ubuntu/test/setup/settings.py
      regexp: "ALLOWED_HOSTS"
      line: 'ALLOWED_HOSTS = ["*"]'
      backrefs: yes
    become_user: ubuntu

  - name: Run database migrations
    shell: ". /home/ubuntu/venv/bin/activate; python /home/ubuntu/test/manage.py migrate"
    become_user: ubuntu

  - name: Load initial data fixtures
    shell: ". /home/ubuntu/venv/bin/activate; python /home/ubuntu/test/manage.py loaddata clientes.json"
    become_user: ubuntu

  - name: Start Django development server in background (detached)
    shell: ". /home/ubuntu/venv/bin/activate; nohup python /home/ubuntu/test/manage.py runserver 0.0.0.0:8000 &"
    async: 45
    poll: 0
    become_user: ubuntu
EOT

ansible-playbook /home/ubuntu/playbook.yml -i /home/ubuntu/hosts.yml
