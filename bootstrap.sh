#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

wd=$(pwd)
echo "### Initializing installation..."
mkdir -p /opt/aaf
cd /opt/aaf
echo "### Installing prerequisite software..."
yum -y install epel-release &>>$wd/install.log
yum -y install git &>>$wd/install.log
yum -y install ansible &>>$wd/install.log
git clone https://github.com/ausaccessfed/idpinstaller.git &>>$wd/install.log
cd idpinstaller
cp hosts /etc/ansible
echo "### Installing your IdP... (This may take some time)"
ansible-playbook software.yml &>>$wd/install.log
echo "IdP installation complete."
echo "For more detailed logs, view file install.log"
