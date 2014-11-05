#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

ipaddr=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')
echo "How do you want to configure your ip address for your idp?"
echo "(Current ip address: ${ipaddr})"
select yn in "Enter new" "Exit" "Use current"; do
  case $yn in
    Enter new) echo "Enter ip address:"
               read usr_reply
               if [ $usr_reply != 0 ]; then
                 ipaddr=$usr_reply
               else
                 echo "Invalid entry"
               fi
               break;;
    Exit) exit;;
    Use current) echo "Using current detected ip: ${ipaddr}"
                 break;;
  esac
done

wd=$(pwd)
echo "### Initializing installation..." | tee -a $wd/install.log
mkdir -p /opt/aaf
cd /opt/aaf
echo "### Installing prerequisite software..." | tee -a $wd/install.log
yum -y install epel-release &>>$wd/install.log
yum -y install libselinux-python &>>$wd/install.log
yum -y install git &>>$wd/install.log
yum -y install ansible &>>$wd/install.log
git clone https://github.com/ausaccessfed/idpinstaller.git &>>$wd/install.log
cd idpinstaller
cp hosts /etc/ansible
echo "### Installing your IdP... (This may take some time)" \
     | tee -a $wd/install.log
ansible-playbook software.yml &>>$wd/install.log
echo "IdP installation complete." | tee -a $wd/install.log
echo "For more details, view install.log" | tee -a $wd/install.log
