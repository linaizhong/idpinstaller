#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

SERV_NAME=$(hostname)
IP_ADDR=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')
ENVIRONMENT_TYPE="Test"

LDAP_HOSTNAME=$(hostname)
LDAP_PORT=389
LDAP_SEARCHBASE=""
LDAP_DN=""
LDAP_PASSWD=""
LDAP_CONN_TYPE="ldap"
LDAP_PACKAGE="other"

ENTITYID=""

UAPPROVE_TOU="true"

# arguments are passed to this function in the following order:
# $1 -> user friendly description of value to be set
# $2 -> default value
user_input() {
  printf "Enter value for $1 [Current: $2]: "
  read response
  if [ -n "$response" ]; then
    case $1 in
      "server name" )
        result=$(validate_hostname $response)
        if [ $result == 0 ]; then
          SERV_NAME=$response
        else
          printf "Invalid hostname. Aborting...\n"
          exit
        fi
        ;;
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
      "LDAP hostname" )
        LDAP_HOSTNAME=$response;;
      "LDAP software package (AD/other)" )
        LDAP_PACKAGE=$response;;
      "LDAP port" )
        LDAP_PORT=$response;;
      "LDAP search base" )
        LDAP_SEARCHBASE=$response;;
      "LDAP distinguished name" )
        LDAP_DN=$response;;
      "LDAP password" )
        LDAP_PASSWD=$response;;
      "LDAP connection type" )
        LDAP_CONN_TYPE=$response;;
      "entity id" )
        ENTITYID=$response;;
      "terms of use (true/false)" )
        result=$(validate_uapprove_tou $response)
        if [ $result == 0 ]; then
          UAPPROVE_TOU=$response
        else
          printf "Invalid value. Aborting...\n"
          exit
        fi
        ;;
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
      "LDAP hostname" )
        LDAP_HOSTNAME=$2;;
      "LDAP software package (AD/other)" )
        LDAP_PACKAGE=$2;;
      "LDAP port" )
        LDAP_PORT=$2;;
      "LDAP search base" )
        LDAP_SEARCHBASE=$2;;
      "LDAP distinguished name" )
        LDAP_DN=$2;;
      "LDAP password" )
        LDAP_PASSWD=$2;;
      "LDAP connection type" )
        LDAP_CONN_TYPE=$2;;
      "entity id" )
        ENTITYID=$2;;
      "terms of use (true/false)" )
        UAPPROVE_TOU=$2;;
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

# returns 0 on valid hostname. 1 otherwise
validate_hostname() {
  if [ $1 != "localhost.localdomain" ]; then
    echo 0
    return
  fi
  echo 1
}

# returns 0 on valid entry. 1 otherwise
validate_uapprove_tou() {
  if [[ $1 == "true" || $1 == "false" ]]; then
    echo 0
    return
  fi
  echo 1
}

user_input "server name" $(hostname)
user_input "ip address" $(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')
user_input "environment type" "Test"
user_input "LDAP hostname" $(hostname)
user_input "LDAP software package (AD/other)" "other"
user_input "LDAP port" 389
user_input "LDAP search base" ""
user_input "LDAP distinguished name" ""
user_input "LDAP password" ""
user_input "entity id" "https://$(hostname)/idp/shibboleth"
user_input "LDAP connection type" "ldap"
user_input "terms of use (true/false)" "true"

printf "Confirm below values:\n"
printf "Server name: $SERV_NAME\n"
printf "IP Address: $IP_ADDR\n"
printf "Environment type: $ENVIRONMENT_TYPE\n"
printf "LDAP hostname: $LDAP_HOSTNAME\n"
printf "LDAP software package: $LDAP_PACKAGE\n"
printf "LDAP port: $LDAP_PORT\n"
printf "LDAP search base: $LDAP_SEARCHBASE\n"
printf "LDAP distinguished name: $LDAP_DN\n"
printf "LDAP connection type: $LDAP_CONN_TYPE\n"
printf "Entity ID: $ENTITYID\n"
read -p "Is this correct? [y/N]: " prompt
case $prompt in
  [yY][eE][sS]|[yY] )
    ;;
  * )
    current_script=$(readlink -f $0)
    exec bash $current_script;;
esac

wd=$(pwd)
which ldapsearch &>/dev/null || { echo "ldapsearch is not installed. Installing now" &>>$wd/install.log; yum -y install openldap-clients &>>$wd/install.log; }
ldapsearch -b $LDAP_SEARCHBASE -H $LDAP_CONN_TYPE://$LDAP_HOSTNAME -x -D $LDAP_DN -w $LDAP_PASSWD &>/dev/null

case $? in
  -1 )
    printf "Error $?: Unable to connect\n"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  0 )
    ;;
  1 )
    printf "Error $?: Improperly sequenced operation\n"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  16 )
    printf "Error $?: No such attribute\n"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  17 )
    printf "Error $?: Undefined attribute type"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  32 )
    printf "Error $?: No such object (user DN or base DN wrong)\n"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  49 )
    printf "Error $?: Invalid credentials (username or password wrong)\n"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  50 )
    printf "Error $?: Insufficient access rights\n"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  80 )
    printf "Error $?: Internal error\n"
    current_script=$(readlink -f $0)
    exec bash $current_script;;
  * )
    current_script=$(readlink -f $0)
    exec bash $current_script;;
esac

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
echo "ldap_hostname: ${LDAP_HOSTNAME}" >> group_vars/idp.yml
echo "ldap_software_package: ${LDAP_PACKAGE}" >> group_vars/idp.yml
echo "ldap_port: ${LDAP_PORT}" >> group_vars/idp.yml
echo "ldap_searchbase: ${LDAP_SEARCHBASE}" >> group_vars/idp.yml
echo "ldap_dn: ${LDAP_DN}" >> group_vars/idp.yml
echo "ldap_passwd: ${LDAP_PASSWD}" >> group_vars/idp.yml
echo "ldap_conn_type: ${LDAP_CONN_TYPE}" >> group_vars/idp.yml
echo "entity_id: ${ENTITYID}" >> group_vars/idp.yml
echo "tou: ${UAPPROVE_TOU}" >> group_vars/idp.yml

echo "### Installing your IdP... (This may take some time)" \
     | tee -a $wd/install.log
ansible-playbook software.yml &>>$wd/install.log
echo "IdP installation complete." | tee -a $wd/install.log
echo "For more details, view install.log" | tee -a $wd/install.log
