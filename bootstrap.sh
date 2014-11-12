#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

SERV_NAME=$(hostname)
IP_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')
ENVIRONMENT_TYPE="Test"

LDAP_SERV_NAME=$(hostname)
LDAP_PORT=389
LDAP_DN=""
LDAP_PASSWD=""
LDAP_CONN_TYPE="LDAP"
LDAP_PACKAGE="other"

# arguments are passed to this function in the following order:
# $1 -> user friendly description of value to be set
# $2 -> default value
user_input() {
  printf "Enter value for $1 [Current: $2]: "
  read response
  if [ -n "$response" ]; then
    case $1 in
      "server name" )
        SERV_NAME=$response;;
      "ip address" )
        result=$(validate_ip_addr $response)
        if [ $result == 0 ]; then
          IP_ADDR=$response
        else
          printf "Invalid value. Aborting...\n"
          exit
        fi
        ;;
      "environment type" )
        if [[ "$response" != "Test" && "$response" != "Production" ]]; then
          printf "Invalid value. Must be \"Production\" or \"Test\". Aborting...\n"
          exit
        else
          ENVIRONMENT_TYPE=$response
        fi
        ;;
      "LDAP server name" )
        LDAP_SERV_NAME=$response;;
      "LDAP software package (AD/other)" )
        LDAP_PACKAGE=$response;;
      "LDAP port" )
        LDAP_PORT=$response;;
      "LDAP distinguished name" )
        LDAP_DN=$response;;
      "LDAP password" )
        LDAP_PASSWD=$response;;
      "LDAP connection type" )
        LDAP_CONN_TYPE=$response;;
    esac
  else
    # defaults should be selected
    case $1 in
      "server_name" )
        SERV_NAME=$2;;
      "ip address" )
        IP_ADDR=$2;;
      "environment type" )
        ENVIRONMENT_TYPE=$2;;
      "LDAP server name" )
        LDAP_SERV_NAME=$2;;
      "LDAP software package (AD/other)" )
        LDAP_PACKAGE=$2;;
      "LDAP port" )
        LDAP_PORT=$2;;
      "LDAP distinguished name" )
        LDAP_DN=$2;;
      "LDAP password" )
        LDAP_PASSWD=$2;;
      "LDAP connection type" )
        LDAP_CONN_TYPE=$2;;
    esac
  fi
}

# returns 0 on a valid ip address structure. 1 otherwise
validate_ip_addr() {
  if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo 0
    return
  fi
  echo 1
}

user_input "server name" $(hostname)
user_input "ip address" $(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')
user_input "environment type" "Test"
user_input "LDAP server name" $(hostname)
user_input "LDAP software package (AD/other)" "other"
user_input "LDAP port" 389
user_input "LDAP distinguished name" ""
user_input "LDAP password" ""
user_input "LDAP connection type" "LDAP"


printf "Confirm below values:\n"
printf "Server name: $SERV_NAME\n"
printf "IP Address: $IP_ADDR\n"
printf "Environment type: $ENVIRONMENT_TYPE\n"
printf "LDAP server name: $LDAP_SERV_NAME\n"
printf "LDAP software package: $LDAP_PACKAGE\n"
printf "LDAP port: $LDAP_PORT\n"
printf "LDAP distinguished name: $LDAP_DN\n"
printf "LDAP connection type: $LDAP_CONN_TYPE\n"
read -p "Is this correct? [y/N]: " prompt
case $prompt in
  [yY][eE][sS]|[yY] )
    ;;
  * )
    current_script=$(readlink -f $0)
    exec bash $current_script;;
esac

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
