This script will take a fresh Ubuntu 14/15 server and update, then install Nginx, Php5-fpm, Percona (MySQL), and Pagespeed, then set up the server configuration for WordPress. It will also install Wordpress (have to run the web installer after), setting up their files and MySQL databases.

To use, login to your server and run the following:

cd to the directory you want to put the script in. I usually just go to root:

cd

wget -q https://raw.githubusercontent.com/dwdonline/lemp-wp/master/lemp_wp_16.sh

chmod 550 lemp_wp_16.sh

./lemp_wp_16.sh
