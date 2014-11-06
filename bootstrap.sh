#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

SERV_NAME="localhost.localdomain.com"
IP_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')
ENVIRONMENT_TYPE="Test"

echo "Enter server name of the server or choose default values"
echo "(Default: ${SERV_NAME})"
select opt in "New" "Default"; do
  case $opt in
    New) echo "Enter server name"
         read usr_reply
           if [ -n "$usr_reply" ]; then
             SERV_NAME=$usr_reply
             echo "Using user supplied value: ${SERV_NAME}"
           else
             echo "Invalid entry. Press Enter to try again."
             continue;
           fi
         break;;
    Default) echo "Using default server name: ${SERV_NAME}"
             break;;
  esac
done

echo "Select environment type"
select opt in "Test" "Production"; do
  case $opt in
    Test) echo "Selected Test environment"
          ENVIRONMENT_TYPE="Test"
          break;;
    Production) echo "Selected Production environment"
                ENVIRONMENT_TYPE="Production"
                break;;
  esac
done

echo "How do you want to configure your ip address for your idp?"
echo "(Current ip address: ${IP_ADDR})"
echo "List of ip addresses available:"
ip addr | awk '/inet / {print$2}' | cut -d/ -f1
select opt in "New" "Current"; do
  case $opt in
    New) echo "Enter ip address:"
         read usr_reply
           if [ $usr_reply != 0 ]; then
             IP_ADDR=$usr_reply
             echo "Using user supplied value: ${IP_ADDR}"
           else
             echo "Invalid entry. Press Enter to try again."
             continue
           fi
         break;;
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
echo "### Building config file..."
echo "ip: ${IP_ADDR}" >> group_vars/idp.yml
echo "server_name: ${SERV_NAME}" >> group_vars/idp.yml
echo "environment_type: ${ENVIRONMENT_TYPE}" >> group_vars/idp.yml

echo "### Installing your IdP... (This may take some time)" \
     | tee -a $wd/install.log
ansible-playbook software.yml &>>$wd/install.log
echo "IdP installation complete." | tee -a $wd/install.log
echo "For more details, view install.log" | tee -a $wd/install.log
