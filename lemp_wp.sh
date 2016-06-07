#!/bin/bash
#### Installation script to setup Ubuntu, Nginx, Percona, Php-fpm, Wordpress
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
 read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! FIRST WE NEED TO MAKE SURE THE SYSTEM IS UP TO DATE!"
pause

apt-get update
apt-get -y upgrade

echo "---> NOW, LET'S BUILD THE ESSENTIALS AND INSTALL ZIP/UNZIP"
pause

apt-get update
apt-get -y install build-essential zip unzip

echo "---> Let's add a new admin user and block the default root from logging in:"
pause

read -e -p "---> What would you like your new admin user to be?: " -i "" NEW_ADMIN
read -e -p "---> What should the new admin password be?: " -i "" NEW_ADMIN_PASSWORD
read -e -p "---> What should we make the SSH port?: " -i "" NEW_SSH_PORT

adduser ${NEW_ADMIN} --disabled-password --gecos ""
echo "${NEW_ADMIN}:${NEW_ADMIN_PASSWORD}"|chpasswd

gpasswd -a ${NEW_ADMIN} sudo

sed -i "s,PermitRootLogin yes,PermitRootLogin no,g" /etc/ssh/sshd_config

sed -i "s,Port 22,Port ${NEW_SSH_PORT},g" /etc/ssh/sshd_config

service ssh restart

echo "---> ALRIGHT, NOW WE ARE READY TO INSTALL THE GOOD STUFF!"
pause

echo "---> INSTALLING NGINX AND PHP-FPM"

nginx=development

add-apt-repository ppa:nginx/$nginx

apt-get -y update

add-apt-repository -y ppa:ondrej/php5-5.6

apt-get -y update

apt-get -y install php5-fpm php5-mhash php5-mcrypt php5-curl php5-cli php5-mysql php5-gd php5-intl php5-xsl libperl-dev libpcre3 libpcre3-dev libssl-dev php5-gd libgd2-xpm-dev libgeoip-dev libgd2-xpm-dev nginx

echo "---> NOW, LET'S COMPILE NGINX WITH PAGESPEED"
pause

cd
wget -q https://github.com/pagespeed/ngx_pagespeed/archive/master.zip
unzip master.zip
cd ngx_pagespeed-master
wget -q https://dl.google.com/dl/page-speed/psol/1.11.33.2.tar.gz
tar -xzvf 1.11.33.2.tar.gz # expands to psol/
cd
wget -q http://nginx.org/download/nginx-1.10.1.tar.gz
tar -xzvf nginx-1.10.1.tar.gz
cd nginx-1.10.1

./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --with-http_stub_status_module --user=www-data --group=www-data --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_image_filter_module --add-module=$HOME/ngx_pagespeed-master --with-ipv6 --with-http_geoip_module --with-http_realip_module;

make

make install

service nginx restart

echo "---> INSTALLING PERCONA"
pause

echo
read -e -p "---> What do you want your MySQL root password to be?: " -i "" MYSQL_ROOT_PASSWORD
read -e -p "---> What version of Ubuntu? 14 is trusty, 15 is wily: " -i "wily" UBUNTU_VERSION

apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A

echo "deb http://repo.percona.com/apt ${UBUNTU_VERSION} main" >> /etc/apt/sources.list

echo "deb-src http://repo.percona.com/apt ${UBUNTU_VERSION} main" >> /etc/apt/sources.list

touch /etc/apt/preferences.d/00percona.pref

echo "Package: *" >> /etc/apt/preferences.d/00percona.pref
echo "Pin: release o=Percona Development Team" >> /etc/apt/preferences.d/00percona.pref
echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/00percona.pref

apt-get -y update

export DEBIAN_FRONTEND=noninteractive
echo "percona-server-server-5.7 percona-server-server/root_password password ${MYSQL_ROOT_PASSWORD}" | sudo debconf-set-selections
echo "percona-server-server-5.7 percona-server-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | sudo debconf-set-selections
apt-get -y install percona-server-server-5.7 percona-server-client-5.7

echo "---> NOW, LET'S SETUP SSL. YOU'LL NEED TO ADD YOUR CERTIFICATE LATER"
pause

echo
read -e -p "---> What will your domain name be (without the www): " -i "domain.com" MY_DOMAIN

cd "/etc/ssl/"

mkdir "sites"

cd "sites"

openssl genrsa -out ${MY_DOMAIN}.key 2048
openssl req -new -key ${MY_DOMAIN}.com.key -out ${MY_DOMAIN}.com.csr

cd

echo "---> OK, WE ARE DONE SETTING UP THE SERVER. LET'S PROCEED TO CONFIGURING THE NGINX HOST FILES FOR WORDPRESS"
pause

#### Install nginx configuration
#### IT WILL REMOVE ALL CONFIGURATION FILES THAT HAVE BEEN PREVIOUSLY INSTALLED.

#NGINX_EXTRA_CONF="defaults.conf exclusions.conf fastcgi-cache.conf fastcgi-params.conf gzip.conf http.conf limits.conf mime-types.conf security.conf ssl.conf static-files.conf"
#NGINX_EXTRA_CONF_URL="https://raw.githubusercontent.com/dwdonline/lemp-wp/master/nginx/wordpress/"

echo "---> CREATING NGINX CONFIGURATION FILES NOW"
echo

read -e -p "---> Enter your domain name (without www.): " -i "domain.com" MY_DOMAIN
read -e -p "---> Enter your web root path: " -i "/var/www/html" MY_SITE_PATH
read -e -p "---> Enter your web user usually www-data (nginx for Centos): " -i "www-data" MY_WEB_USER

cd /etc/nginx
mkdir -p wordpress
cd wordpress

wget -qO  /etc/nginx/wordpress/defaults.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/defaults.conf
wget -qO  /etc/nginx/wordpress/exclusions.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/exclusions.conf
wget -qO  /etc/nginx/wordpress/fastcgi-cache.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/fastcgi-cache.conf
wget -qO  /etc/nginx/wordpress/fastcgi-params.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/fastcgi-params.conf
wget -qO  /etc/nginx/wordpress/gzip.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/gzip.conf
wget -qO  /etc/nginx/wordpress/http.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/http.conf
wget -qO  /etc/nginx/wordpress/limits.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/limits.conf
wget -qO  /etc/nginx/wordpress/mime-types.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/mime-types.conf
wget -qO  /etc/nginx/wordpress/security.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/security.conf
wget -qO  /etc/nginx/wordpress/ssl.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/ssl.conf
wget -qO  /etc/nginx/wordpress/static-files.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/wordpress/static-files.conf
wget -qO  /etc/nginx/conf.d/pagespeed.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/conf.d/pagespeed.conf

cd ../
mv nginx.conf nginx.conf.bak
wget -qO  /etc/nginx/wordpress/nginx.conf https://github.com/dwdonline/lemp-wp/blob/master/nginx/nginx.conf

#sed -i "s/www/sites-enabled/g" /etc/nginx/nginx.conf

mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
wget -q https://raw.githubusercontent.com/dwdonline/lemp-wp/master/nginx/sites-available/default.conf
wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/lemp-wp/master/nginx/sites-available/domain.conf

sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s/www.example.com/www.${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,root /var/www/html,root ${MY_SITE_PATH},g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,user  www-data,user  ${MY_WEB_USER},g" /etc/nginx/nginx.conf
#sed -i "s,listen = /var/run/php5-fpm.sock,listen = 127.0.0.1:9000,g" /etc/php5/fpm/pool.d/www.conf

ln -s /etc/nginx/sites-available/${MY_DOMAIN}.conf/etc/nginx/sites-enabled/${MY_DOMAIN}.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

#cd /etc/nginx/conf.d/
#for CONFIG in ${NGINX_EXTRA_CONF}
#do
#wget -q ${NGINX_EXTRA_CONF_URL}${CONFIG}
#done

#sed -i "s,pagespeed  FileCachePath,#pagespeed  FileCachePath,g" /etc/nginx/conf.d/pagespeed.conf
#sed -i "s,pagespeed  LogDir,#pagespeed  LogDir,g" /etc/nginx/conf.d/pagespeed.conf

#sed -i '/http   {/a     ## Pagespeed module\n    pagespeed  FileCachePath  "/var/tmp/";\n    pagespeed  LogDir "/var/log/pagespeed";\n    pagespeed ProcessScriptVariables on;\n' /etc/nginx/nginx.conf

read -p "Would you like to install Adminer for managing your MySQL databases now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
cd "/var/www/"
mkdir -p ${MY_SITE_PATH}
cd ${MY_SITE_PATH}

wget -q https://www.adminer.org/static/download/4.2.4/adminer-4.2.4-mysql.php
mv adminer-4.2.4-mysql.php adminer.php
else
  exit 0
fi

echo "---> Let's install Postfix to handle sending mail:"
pause

read -e -p "---> What would you like your host to be? I like it to be something like mail.domain.com: " -i "" POSTFIX_SERVER

debconf-set-selections <<< "postfix postfix/mailname string ${POSTFIX_SERVER}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix

read -p "Would you like to install WordPress now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

cd "/var/www/${MY_SITE_PATH}"

wget -q https://wordpress.org/latest.zip

unzip latest.zip

#mv wordpress blog

echo
read -e -p "---> What do you want to name your WordPress MySQL database?: " -i "" WP_MYSQL_DATABASE
read -e -p "---> What do you want to name your WordPress MySQL user?: " -i "" WP_MYSQL_USER
read -e -p "---> What do you want your WordPress MySQL password to be?: " -i "" WP_MYSQL_USER_PASSWORD

echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${MYSQL_DATABASE}; CREATE user '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${WP_MYSQL_DATABASE}.* TO '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${WP_MYSQL_DATABASE}"
echo "Your database user is: ${WP_MYSQL_USER}"
echo "Your databse password is: ${WP_MYSQL_USER_PASSWORD}"

else
  exit 0
fi

echo "---> Let's set the permissions for WordPresss:"
pause

echo "Lovely, this may take a few minutes. Dont fret."

cd "/var/www/${MY_SITE_PATH}"

chown -R ${NEW_ADMIN.www-data *

find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \; 

find wp-content/ -type f -exec chmod 600 {} \; 
find wp-content/ -type d -exec chmod 700 {} \;

echo "---> Let;s cleanup:"
pause
cd
rm -rf master.zip nginx-1.10.1 nginx-1.10.1.tar.gz ngx_pagespeed-master

echo "I just saved you a shitload of time and headache. You're welcome."
