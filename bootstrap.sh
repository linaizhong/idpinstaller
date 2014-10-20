#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

yum -y install epel-release
yum -y install git
yum -y install ansible
mkdir -p /opt/aaf-ansible
cd /opt/aaf-ansible
git clone https://github.com/j-tan/idp-playbook.git
cd idp-playbook
cp hosts /etc/ansible
ansible-playbook software.yml
