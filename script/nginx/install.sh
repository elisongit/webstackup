#!/usr/bin/env bash
### AUTOMATIC NGINX INSTALL BY WEBSTACK.UP
# sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/webstackup/master/script/nginx/install.sh?$(date +%s) | sudo bash
#

echo ""
echo -e "\e[1;46m ================ \e[0m"
echo -e "\e[1;46m 📰 NGINX INSTALL \e[0m"
echo -e "\e[1;46m ================ \e[0m"

if ! [ $(id -u) = 0 ]; then
  echo -e "\e[1;41m This script must run as ROOT \e[0m"
  exit
fi
  
## Add Nginx key and repo
apt update
apt install curl gnupg2 ca-certificates lsb-release unzip nano -y
curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
echo "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ $(lsb_release -sc) nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ $(lsb_release -sc) nginx" >> /etc/apt/sources.list.d/nginx.list
  
## Pinning the repo
NGINX_PINNING_FILE=/etc/apt/preferences.d/99-nginx-webstackup
echo "Package: nginx" > $NGINX_PINNING_FILE
echo -n "Pin: release a=" >> $NGINX_PINNING_FILE
echo "$(lsb_release -sc)" >> $NGINX_PINNING_FILE
echo "Pin-Priority: -900" >> $NGINX_PINNING_FILE
  
## Install Nginx
apt update -qq
apt install nginx -y

if [ -f "/usr/local/turbolab.it/webstackup/config/nginx/85_status_page.conf" ] && [ ! -f "/etc/nginx/conf.d/status_page.conf" ]; then

  ln -s /usr/local/turbolab.it/webstackup/config/nginx/85_status_page.conf /etc/nginx/conf.d/status_page.conf

elif [ ! -f "/etc/nginx/conf.d/status_page.conf" ]; then
  
  curl -o "/etc/nginx/conf.d/status_page.conf" https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/nginx/85_status_page.conf
fi

## Start the service
service nginx restart
