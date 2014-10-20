idp-playbook
============

Installs the latest version of Shibboleth IdP

###Usage:
Download the bootstrap.sh file by executing the following command:
```
wget https://raw.githubusercontent.com/j-tan/idp-playbook/master/bootstrap.sh
```
Once the file has completed downloading, execute it as root with:
```
sh ./bootstrap.sh
```
Note: If you are not root, the script will throw an error.

###Services that script will setup:
- Secure HTTP web server
- Database server
- Time synchronisation
- Java and associated development kits
- JSP server
