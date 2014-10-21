#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "### Creating directory /opt/aaf..."
mkdir -p /opt/aaf
echo "Complete"
echo "- Navigating to /opt/aaf"
cd /opt/aaf
echo "### Installing EPEL..."
yum -y install epel-release &>>install.log
echo "Complete"
echo "### Installing git..."
yum -y install git &>>install.log
echo "Complete"
echo "### Installing ansible..."
yum -y install ansible &>>install.log
echo "Complete"
echo "### cloning from remote git repository..."
git clone https://github.com/ausaccessfed/idpinstaller.git &>>install.log
echo "- Navigating to repository"
cd idpinstaller
echo "### Copying over new ansible hosts file..."
cp hosts /etc/ansible
echo "Complete"
echo "### Running ansible playbook file..."
ansible-playbook software.yml &>>../install.log
echo "Complete"
echo "For more detailed logs, view file install.log"
