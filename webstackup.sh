#!/bin/bash
clear

## Script name
SCRIPT_NAME=webstackup

## Install directory
WORKING_DIR_ORIGINAL="$(pwd)"
INSTALL_DIR_PARENT="/usr/local/turbolab.it/"
INSTALL_DIR=${INSTALL_DIR_PARENT}${SCRIPT_NAME}/
AUTOGENERATED_DIR="${INSTALL_DIR}autogenerated/"

## Title and graphics
FRAME="O===========================================================O"
echo "$FRAME"
echo "      WEBSTACK.UP - $(date)"
echo "$FRAME"

## Enviroment variables
TIME_START="$(date +%s)"
DOWEEK="$(date +'%u')"
HOSTNAME="$(hostname)"

## Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT_FULLPATH=$(readlink -f "$0")
SCRIPT_HASH=`md5sum ${SCRIPT_FULLPATH} | awk '{ print $1 }'`

## Absolute path this script is in, thus /home/user/bin
SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

## Config file path from CLI (if any)
CONFIGFILE_FULLPATH=$1


## Title printing function
function printTitle
{
	STYLE='\033[44m'
	RESET='\033[0m'

    echo ""
	echo -n -e $STYLE
    echo "$1"
    printf '%0.s-' $(seq 1 ${#1})
	echo -e $RESET
	echo ""
}


function printMessage
{
	STYLE='\033[43m'
	RESET='\033[0m'

	echo -n -e $STYLE
    echo "$1"
	echo -e $RESET
	echo ""
}


## root check
if ! [ $(id -u) = 0 ]; then

	echo ""
	echo "vvvvvvvvvvvvvvvvvvvv"
	echo "Catastrophic error!!"
	echo "^^^^^^^^^^^^^^^^^^^^"
	echo "This script must run as root!"

	printTitle "How to fix it?"
	echo "Execute the script like this:"
	echo "sudo $SCRIPT_NAME"

	printTitle "The End"
	echo $(date)
	echo "$FRAME"
	exit
fi


## Default config
DEFAULT_CONFIG_URL=https://raw.githubusercontent.com/TurboLabIt/webstackup/master/webstackup.default.conf
source <(curl -s ${DEFAULT_CONFIG_URL})

## Default config error!
if [[ $ZZWEBSERVERSETUP_ENABLED != 1 ]]; then

	echo ""
	echo "vvvvvvvvvvvvvvvvvvvv"
	echo "Catastrophic error!!"
	echo "^^^^^^^^^^^^^^^^^^^^"
	echo "Default config file not available or script disabled"

	printTitle "How to fix it?"
	echo "Please check that the following file exists and is accessible:"
	echo "$DEFAULT_CONFIG_URL"
	
	echo ""
	echo "Let me curl it for you (this will probably give an error):"
	curl $DEFAULT_CONFIG_URL

	printTitle "The End"
	echo $(date)
	echo "$FRAME"
	exit
fi


## Config file from CLI, error!
if [ ! -z "$CONFIGFILE_FULLPATH" ] && [ ! -f "$CONFIGFILE_FULLPATH" ]; then

	echo ""
	echo "vvvvvvvvvvvvvvvvvvvv"
	echo "Catastrophic error!!"
	echo "^^^^^^^^^^^^^^^^^^^^"
	echo "Config file not found!"

	printTitle "How to fix it?"
	echo "Please check that the following file exists and is accessible:"
	echo "$CONFIGFILE_FULLPATH"
	
	echo ""
	echo "Let me cat it for you (will probably give an error):"
	cat "$CONFIGFILE_FULLPATH"

	printTitle "The End"
	echo $(date)
	echo "$FRAME"
	exit
fi

## Config file from CLI OK
if [ ! -z "$CONFIGFILE_FULLPATH" ]; then
	
	printTitle "Importing custom options"
	source "$CONFIGFILE_FULLPATH"
	
	echo "Custom options imported from"
	echo $(readlink -f "$CONFIGFILE_FULLPATH")
fi

## =========== NGINX ===========
printTitle "Installing Nginx"

if [ $INSTALL_NGINX = 1 ]; then

	apt-get purge --auto-remove nginx* -y

	curl -L -o nginx_signing.key http://nginx.org/keys/nginx_signing.key
	apt-key add nginx_signing.key
	rm -f nginx_signing.key

	NGINX_SOURCE_FULLPATH=/etc/apt/sources.list.d/${SCRIPT_NAME}.nginx.list
	
	touch "$NGINX_SOURCE_FULLPATH"
	echo "### webstackup" >> "$NGINX_SOURCE_FULLPATH"
	echo "deb http://nginx.org/packages/mainline/ubuntu/ $(lsb_release -sc) nginx"  >> "$NGINX_SOURCE_FULLPATH"
	echo "deb-src http://nginx.org/packages/mainline/ubuntu/ $(lsb_release -sc) nginx"  >> "$NGINX_SOURCE_FULLPATH"
	
	echo ""
	printMessage "$(cat "$NGINX_SOURCE_FULLPATH")"

	apt-get update
	apt install nginx -y

	systemctl restart nginx
	systemctl  --no-pager status nginx
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== PHP ===========
printTitle "Installing PHP-CLI and PHP-FPM"

if [ $INSTALL_PHP = 1 ]; then
	
	apt-get purge --auto-remove php* -y
	LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
	apt-get update

	## mcrypt is discontinued since PHP 7.2
	apt-get install php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-common php${PHP_VER}-mbstring php${PHP_VER}-gd php${PHP_VER}-intl php${PHP_VER}-xml php${PHP_VER}-mysql php${PHP_VER}-zip php${PHP_VER}-curl -y
	
	## Service hardening
	sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/${PHP_VER}/fpm/php.ini
	printMessage "$(cat /etc/php/${PHP_VER}/fpm/php.ini | grep 'cgi.fix_pathinfo=')"
	
	## Remove version name from listening socket file
	sed -i -e "s|listen = /run/php/php${PHP_VER}-fpm.sock|listen = /run/php/php-fpm.sock|g" /etc/php/${PHP_VER}/fpm/pool.d/www.conf
	printMessage "$(cat /etc/php/${PHP_VER}/fpm/pool.d/www.conf | grep 'listen = ')"
	
	systemctl restart php${PHP_VER}-fpm
	systemctl  --no-pager status php${PHP_VER}-fpm
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== MySQL ===========
printTitle "Installing MySQL"

if [ $INSTALL_MYSQL = 1 ]; then
	
	apt-get purge --auto-remove mysql* -y

	apt-key adv --keyserver keys.gnupg.net --recv-keys 5072E1F5

	touch /etc/apt/sources.list.d/webstackup.mysql.list
	echo "### webstackup" >> /etc/apt/sources.list.d/webstackup.mysql.list
	echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-${MYSQL_VER}" >> /etc/apt/sources.list.d/webstackup.mysql.list
	echo "deb-src http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-${MYSQL_VER}" >> /etc/apt/sources.list.d/webstackup.mysql.list
	echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-tools" >> /etc/apt/sources.list.d/webstackup.mysql.list
	
	echo ""
	printMessage "$(cat /etc/apt/sources.list.d/webstackup.mysql.list)"
	
	MYSQL_ROOT_PASSWORD="$(head /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 18)"
	debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"
	debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"
	debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select"
	
	printMessage "MySQL root password is now: ##$MYSQL_ROOT_PASSWORD##"

	apt-get update
	apt-get install mysql-server mysql-client -y

	systemctl restart mysql
	systemctl  --no-pager status mysql
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== Composer ===========
printTitle "Installing composer"

if [ $INSTALL_COMPOSER = 1 ]; then

	COMPOSER_EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	COMPOSER_ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
	
	if [ "$COMPOSER_EXPECTED_SIGNATURE" != "$COMPOSER_ACTUAL_SIGNATURE" ]; then
	
		echo "vvvvvvvvvvvvvvvvvvvv"
		echo "Catastrophic error!!"
		echo "^^^^^^^^^^^^^^^^^^^^"
		echo "Composer signature doesn't match! Abort! Abort!"
		
		echo ""
		echo "Expec. sign: ### ${COMPOSER_EXPECTED_SIGNATURE}"
		echo "Actual sign: ### ${COMPOSER_ACTUAL_SIGNATURE}"
		
		printTitle "The End"
		echo $(date)
		echo "$FRAME"
		exit
		
	fi
	
	php composer-setup.php --filename=composer --install-dir=/usr/local/bin
	php -r "unlink('composer-setup.php');"
	
	echo ""
	printMessage "$(composer --version)"
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== zzupdate ===========
printTitle "Installing zzupdate"

if [ $INSTALL_ZZUPDATE = 1 ]; then

	curl -s https://raw.githubusercontent.com/TurboLabIt/zzupdate/master/setup.sh | sudo sh
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== zzmysqldump ===========
printTitle "Installing zzmysqldump"

if [ $INSTALL_ZZMYSQLDUMP = 1 ]; then

	curl -s https://raw.githubusercontent.com/TurboLabIt/zzmysqldump/master/setup.sh | sudo sh
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== zzwebsebserversetup ===========
printTitle "Installing webstackup (ready-to-use configs and tools)"

if [ $INSTALL_ZZWEBSERVERSETUP = 1 ]; then

	apt install git openssl -y
	
	if [ ! -d "$INSTALL_DIR" ]; then
		echo "Installing..."
		echo "-------------"
		mkdir -p "$INSTALL_DIR_PARENT"
		cd "$INSTALL_DIR_PARENT"
		git clone https://github.com/TurboLabIt/${SCRIPT_NAME}.git
	else
		echo "Updating..."
		echo "-----------"
	fi

	## Fetch & pull new code
	cd "$INSTALL_DIR"
	git pull
	
	## Create folder for autogenerated files
	mkdir -p "${AUTOGENERATED_DIR}"
	
	## Create dhparam file for HTTPS-enabling
	#openssl dhparam 2048 -out "${AUTOGENERATED_DIR}dhparam.pem"
	
	## Create ready-to-use simple HTTP AUTH file
	HTTPAUTH_FULLFILE=${AUTOGENERATED_DIR}httpauth_welcome
	
	echo -n 'wel:' > "$HTTPAUTH_FULLFILE"
	openssl passwd -apr1 'come' >> "$HTTPAUTH_FULLFILE"
	echo '' >> "$HTTPAUTH_FULLFILE"
	
	echo -n 'ben:' >> "$HTTPAUTH_FULLFILE"
	openssl passwd -apr1 'venuto' >> "$HTTPAUTH_FULLFILE"
	echo '' >> "$HTTPAUTH_FULLFILE"
	
	echo ""
	printMessage "Ready-to-use HTTP Auth will be:"
	printMessage "User: wel | Pass: come"
	printMessage "User: ben | Pass: venuto"
	
	printMessage "$(cat "$HTTPAUTH_FULLFILE")"
	
	cd $WORKING_DIR_ORIGINAL
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== xdebug ===========
printTitle "Installing xdebug"

if [ $INSTALL_XDEBUG = 1 ]; then

	apt install php-xdebug -y
	XDEBUG_CONFIG_FILE_FULLPATH="${INSTALL_DIR}config/php/xdebug.ini"
	
	if [ -f "${XDEBUG_CONFIG_FILE_FULLPATH}" ]; then
	
		ln -s "$XDEBUG_CONFIG_FILE_FULLPATH" /etc/php/${PHP_VER}/fpm/conf.d/20-xdebug-zzwebsebserversetup.ini
		ln -s "$XDEBUG_CONFIG_FILE_FULLPATH" /etc/php/${PHP_VER}/cli/conf.d/20-xdebug-zzwebsebserversetup.ini
		
		printMessage "$(cat "/etc/php/${PHP_VER}/cli/conf.d/20-xdebug-zzwebsebserversetup.ini")"
	fi
	
	systemctl restart php${PHP_VER}-fpm
	sleep 5

else
	
	echo "Skipped (disabled in config)"
fi


## =========== Let's Encrypt ===========
printTitle "Installing Let's Encrypt"

if [ $INSTALL_LETSENCRYPT = 1 ]; then

	add-apt-repository ppa:certbot/certbot -y
	apt-get update
	apt install certbot -y
	
	printMessage "$(certbot --version)"
	
	LETSENCRYPT_CRON_FILE_FULLPATH="${INSTALL_DIR}config/letsencrypt/cron_renew"
	
	if [ -f "${LETSENCRYPT_CRON_FILE_FULLPATH}" ]; then
	
		cp "${LETSENCRYPT_CRON_FILE_FULLPATH}" /etc/cron.d/letsencrypt_renew
		printMessage "$(cat "/etc/cron.d/letsencrypt_renew")"
	fi
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== The End ===========
printTitle "THE END"
echo "$((($(date +%s)-$TIME_START)/60)) min."

printTitle "Rebooting"
if [ "$REBOOT" = "1" ]; then
	
	while [ $REBOOT_TIMEOUT -gt 0 ]; do
	   echo -ne "$REBOOT_TIMEOUT\033[0K\r"
	   sleep 1
	   : $((REBOOT_TIMEOUT--))
	done
	reboot

else
	
	echo "Skipped (disabled in config)"
fi

printTitle "The End"
echo $(date)
echo "$FRAME"
