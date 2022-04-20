#!/usr/bin/env bash
### AUTOMATIC Pure-FTPd INSTALL BY WEBSTACK.UP
# sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/webstackup/master/script/pure-ftpd/install.sh?$(date +%s) | sudo bash

echo ""
if ! [ $(id -u) = 0 ]; then
  echo -e "\e[1;41m This script must run as ROOT \e[0m"
  exit
fi

echo ""
echo -e "\e[1;44m Installing Pure-FTPd... \e[0m"
apt update
apt install pure-ftpd  -y

echo ""
echo -e "\e[1;44m Start Pure-FTPd at boot... \e[0m"
systemctl enable pure-ftpd

echo ""
echo -e "\e[1;44m www-data user setup... \e[0m"
if id "www-data" &>/dev/null; then

  echo 'www-data user found'
  
else

  echo 'Creating www-data group...'
  groupadd -f -r www-data
  
  echo 'Creating www-data user...'
  mkdir -p /var/www
  useradd -g www-data -d /var/www -s /sbin/nologin -r www-data
  chown www-data:www-data /var/www -R
fi

echo ""
echo -e "\e[1;44m PassivePortRange... \e[0m"
if [ ! -f "/etc/pure-ftpd/conf/PassivePortRange" ] && [ -f "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PassivePortRange" ]; then

  echo "Linking PassivePortRange..."
  ln -s "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PassivePortRange" "/etc/pure-ftpd/conf/PassivePortRange"

elif [ ! -f "/etc/pure-ftpd/conf/PassivePortRange" ]; then

  echo "Downloading PassivePortRange..."
  curl -Lo "/etc/pure-ftpd/conf/PassivePortRange" https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/pure-ftpd/PassivePortRange
  
else

  echo "PassivePortRange exists, skipping"
  
fi


echo ""
echo -e "\e[1;44m NoAnonymous... \e[0m"
rm -f "/etc/pure-ftpd/conf/NoAnonymous"
if [ -f "/usr/local/turbolab.it/webstackup/config/pure-ftpd/NoAnonymous" ]; then

  echo "Linking NoAnonymous..."
  ln -s "/usr/local/turbolab.it/webstackup/config/pure-ftpd/NoAnonymous" "/etc/pure-ftpd/conf/NoAnonymous"

else

  echo "Downloading NoAnonymous..."
  curl -Lo "/etc/pure-ftpd/conf/NoAnonymous" https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/pure-ftpd/NoAnonymous
  
fi

echo ""
echo -e "\e[1;44m PureDB... \e[0m"
rm -f "/etc/pure-ftpd/conf/PureDB"
if [ -f "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PureDB" ]; then

  echo "Linking PureDB..."
  ln -s "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PureDB" "/etc/pure-ftpd/conf/PureDB"

else

  echo "Downloading PureDB..."
  curl -Lo "/etc/pure-ftpd/conf/PureDB" https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/pure-ftpd/PureDB
  
fi

echo ""
echo -e "\e[1;44m Activating PureDB auth... \e[0m"
if [ ! -f "/etc/pure-ftpd/auth/20PureDB" ]; then
  echo "Linking..."
  ln -s "/etc/pure-ftpd/conf/PureDB" "/etc/pure-ftpd/auth/20PureDB"
else
  echo "Auth exists, skipping"
fi

echo ""
echo -e "\e[1;44m Listing... \e[0m"
ls -lAtrh "/etc/pure-ftpd/conf"

echo ""
echo -e "\e[1;44m Listing FTP users... \e[0m"
if [ ! -f "/etc/pure-ftpd/pureftpd.passwd" ]; then
  touch "/etc/pure-ftpd/pureftpd.passwd"
fi
pure-pw mkdb
pure-pw list
echo ""

echo ""
echo -e "\e[1;44m Restarting... \e[0m"
service pure-ftpd restart