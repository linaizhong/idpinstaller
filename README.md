idp-playbook
============

Ansible playbook to install software needed by Shibboleth IdP

###Usage:
After clonning the repository, navigate to project root and run:
```
sh ./bootstrap.sh
```

###Software packages that script will install:
- httpd
- mod_ssl
- mysql
- mysql-server
- ntp
- java-1.7.0-openjdk
- java-1.7.0-openjdk-devel
- ant
- unzip
- apache-tomcat-7.0.42 (from binary)
