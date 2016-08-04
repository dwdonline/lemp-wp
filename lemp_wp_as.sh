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

echo "---> WELCOME! Let's create a new site! First, we will create the SSL"
pause

echo
read -e -p "---> What will your domain name be (without the www) - ie: domain.com: " -i "" MY_DOMAIN
read -e -p "---> What is your main admin user for SSH?: " -i "" ADMIN_USER

cd /etc/ssl/sites/

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${MY_DOMAIN}.key -out ${MY_DOMAIN}.crt
openssl x509 -in ${MY_DOMAIN}.crt -signkey ${MY_DOMAIN}.key -x509toreq -out ${MY_DOMAIN}.csr

cd

echo "---> OK, LET'S PROCEED TO CONFIGURING THE NGINX HOST FILES FOR WORDPRESS"
pause

echo "---> CREATING NGINX CONFIGURATION FILES NOW"
echo

read -e -p "---> Enter your web root path: " -i "/var/www/${MY_DOMAIN}" MY_SITE_PATH
read -e -p "---> Enter your web user usually www-data (nginx for Centos): " -i "www-data" MY_WEB_USER

cd /etc/nginx/sites-available/
wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/lemp-wp/master/nginx/sites-available/domain.conf

sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,fastcgi_cache_path,fastcgi_cache_path ${MY_SITE_PATH}/fastcgi-cache levels=1:2 keys_zone=${MY_DOMAIN}:100m inactive=60m;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,fastcgi_cache_domain,fastcgi_cache_domain ${MY_DOMAIN};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s/www.example.com/www.${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,root /var/www/html,root ${MY_SITE_PATH},g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,user  www-data,user  ${MY_WEB_USER},g" /etc/nginx/nginx.conf
sed -i "s,ssl_certificate_name,ssl_certificate /etc/ssl/sites/${MY_DOMAIN}.crt;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,ssl_certificate_key,ssl_certificate_key /etc/ssl/sites/${MY_DOMAIN}.key;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,access_log,access_log /var/log/nginx/${MY_DOMAIN}_access.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
sed -i "s,error_log,error_log /var/log/nginx/${MY_DOMAIN}_error.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

ln -s /etc/nginx/sites-available/${MY_DOMAIN}.conf /etc/nginx/sites-enabled/${MY_DOMAIN}.conf

cd "/var/www/"
mkdir -p ${MY_SITE_PATH}

#need to modify postfix to new additional host
#echo "---> Let's modify Postfix to handle sending mail:"
#pause

#read -e -p "---> What would you like your host to be? I like it to be something like mail.domain.com: " -i "" POSTFIX_SERVER

#sed -i "s,mydestination = ,mydestination = ${POSTFIX_SERVER},/,g" /etc/postfix/main.cf

read -p "Would you like to install WordPress now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

cd "${MY_SITE_PATH}"

wget -q https://wordpress.org/latest.zip

unzip latest.zip

cd wordpress
mv * .htaccess ../

echo
read -e -p "---> What do you want to name your WordPress MySQL database?: " -i "" WP_MYSQL_DATABASE
read -e -p "---> What do you want to name your WordPress MySQL user?: " -i "" WP_MYSQL_USER
read -e -p "---> What do you want your WordPress MySQL password to be?: " -i "" WP_MYSQL_USER_PASSWORD


echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${WP_MYSQL_DATABASE}; CREATE user '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${WP_MYSQL_DATABASE}.* TO '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${WP_MYSQL_DATABASE}"
echo "Your database user is: ${WP_MYSQL_USER}"
echo "Your databse password is: ${WP_MYSQL_USER_PASSWORD}"

service mysql restart

cd "${MY_SITE_PATH}"

cp -r wp-config-sample.php wp-config.php

sed -i "s,database_name_here,${WP_MYSQL_DATABASE},g" wp-config.php
sed -i "s,username_here,${WP_MYSQL_USER},g" wp-config.php
sed -i "s,password_here,${WP_MYSQL_USER_PASSWORD},g" wp-config.php

#set WP salts
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php

else
  exit 0
fi

echo "---> Let's add a robots.txt file for WordPresss:"
wget -qO ${MY_SITE_PATH}/robots.txt https://raw.githubusercontent.com/dwdonline/lemp-wp/master/robots.txt

sed -i "s,Sitemap: http://YOUR-DOMAIN.com/sitemap_index.xml,Sitemap: https://www.${MY_DOMAIN}/sitemap_index.xml,g" ${MY_SITE_PATH}/robots.txt

echo "---> Let's set the permissions for WordPresss:"
pause

echo "Lovely, this may take a few minutes. Dont fret."

cd "${MY_SITE_PATH}"

chown -R ${NEW_ADMIN}.www-data *

chown -R ${NEW_ADMIN}.www-data robots.txt

find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \; 

find ${MY_SITE_PATH}/wp-content/ -type f -exec chmod 600 {} \; 
find ${MY_SITE_PATH}/wp-content/ -type d -exec chmod 700 {} \;

echo "---> Let;s cleanup:"
pause
cd
rm -rf master.zip nginx-1.10.1 nginx-1.10.1.tar.gz ngx_pagespeed-master

cd ${MY_SITE_PATH}

rm -rf wordpress

else
  exit 0
  echo "I just saved you a shitload of time and headache. You're welcome."
fi
