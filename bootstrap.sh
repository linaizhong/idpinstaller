#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

SERV_NAME="localhost.localdomain.com"
IP_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')
IDP_VERSION=2.4.3

echo "Enter IdP version or choose default values"
echo "(Default: ${IDP_VERSION})"
select opt in "New" "Default"; do
  case $opt in
    New) echo "Enter version number"
         read usr_reply
           if [ $usr_reply -ne 0 ]; then
             IDP_VERSION=$usr_reply
           fi
           break;;
    Default) echo "Using default IdP version: ${IDP_VERSION}"
             break;;
  esac
done

echo "Configure server name of the server the IdP is to be installed on?"
echo "(Default: ${SERV_NAME})"
select opt in "Yes" "No" "Default"; do
  case $opt in
    Yes) echo "Enter server name"
         read usr_reply
           if [ -n "$usr_reply" ]; then
             SERV_NAME=$usr_reply
           fi
         break;;
    No) exit;;
    Default) echo "Using default server name: ${SERV_NAME}"
             break;;
  esac
done

echo "How do you want to configure your ip address for your idp?"
echo "(Current ip address: ${IP_ADDR})"
select opt in "New" "Exit" "Current"; do
  case $opt in
    New) echo "Enter ip address:"
         read usr_reply
           if [ $usr_reply -ne 0 ]; then
             IP_ADDR=$usr_reply
           else
             echo "Invalid entry. Press Enter to try again."
             continue
           fi
         break;;
    Exit) exit;;
    Current) echo "Using current detected ip: ${IP_ADDR}"
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
