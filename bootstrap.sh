#!/bin/bash
yum -y install epel-release
yum -y install git
yum -y install ansible
mkdir /opt/aaf-ansible
cd /opt/aaf-ansible
git clone git@github.com:j-tan/idp-playbook.git
cd idp-playbook
cp hosts /etc/ansible
ansible-playbook software.yml
