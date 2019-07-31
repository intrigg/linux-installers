#!/bin/bash
# INTRIGG BlueBox + FreeSwitch Installer


#Pre Install Components
yum -y update

rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

yum -y update

yum -y groupinstall core
yum -y groupinstall base

yum -y install git autoconf make automake nano libtool gcc-c++ ncurses-devel make expat-devel zlib zlib-devel libjpeg-devel unixODBC-devel openssl-devel gnutls-devel libogg-devel libvorbis-devel ncurses-devel python-devel zlib zlib-devel bzip2 which pkgconfig curl-devel libtiff-devel mysql-server php php-mysql php-xml


#Verify that SELINUX is disabled
setenforce 0
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
sestatus


#Install Freeswitch
cd /usr/src/
git clone -b v1.2.stable https://stash.freeswitch.org/scm/fs/freeswitch.git
cd freeswitch
./bootstrap.sh && ./configure && make && make install && make all cd-sounds-install cd-moh-install


#Install Freeswitch start/stop script
cd /etc/init.d
touch freeswitch
chmod a+x freeswitch
nano freeswitch

chkconfig --add freeswitch
chkconfig freeswitch on


#Add user freeswitch
adduser freeswitch -M -d /usr/local/freeswitch -s /sbin/nologin -c "Freeswitch user"

chown -R freeswitch. /usr/local/freeswitch
chown -R freeswitch. /var/lib/php/session


#Change apache ownerships
sed -i "s/User apache/User freeswitch/" /etc/httpd/conf/httpd.conf
sed -i "s/Group apache/Group freeswitch/" /etc/httpd/conf/httpd.conf

#Enable all services
chkconfig httpd on
chkconfig mysqld on

service freeswitch start 
service httpd start 
service mysqld start


#Create mysql user account
mysql -e "CREATE USER 'bluebox'@'localhost' IDENTIFIED BY 'bluebox';"
mysql -e "GRANT ALL PRIVILEGES ON bluebox.* TO 'bluebox'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"


#BlueBox Install
cd /var/www/html
git clone git://github.com/2600hz/bluebox.git bluebox
chown -R freeswitch. /var/www/html/bluebox
cd /var/www/html/bluebox
./preinstall.sh

service httpd restart
