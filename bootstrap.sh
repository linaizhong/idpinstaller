#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

yum -y install epel-release
yum -y install git
yum -y install libselinux-python
yum -y install ansible
mkdir -p /opt/aaf
cd /opt/aaf
git clone https://github.com/ausaccessfed/idpinstaller.git
cd idpinstaller
cp hosts /etc/ansible
ansible-playbook software.yml
