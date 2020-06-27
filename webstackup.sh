#!/bin/bash
clear

## Script name
SCRIPT_NAME=webstackup

## Install directory
WORKING_DIR_ORIGINAL="$(pwd)"
INSTALL_DIR_PARENT="/usr/local/turbolab.it/"
INSTALL_DIR=${INSTALL_DIR_PARENT}${SCRIPT_NAME}/
AUTOGENERATED_DIR="${INSTALL_DIR}autogenerated/"

## Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT_FULLPATH=$(readlink -f "$0")

## Absolute path this script is in, thus /home/user/bin
SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

## Title and graphics
FRAME="O===========================================================O"
echo "$FRAME"
echo "      WEBSTACK.UP - $(date)"
echo "$FRAME"

## Enviroment variables
TIME_START="$(date +%s)"
DOWEEK="$(date +'%u')"
HOSTNAME="$(hostname)"


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
	STYLE='\033[45m'
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
if [[ $WEBSTACKUP_ENABLED != 1 ]]; then

	echo ""
	echo "vvvvvvvvvvvvvvvvvvvv"
	echo "Catastrophic error!!"
	echo "^^^^^^^^^^^^^^^^^^^^"
	echo "Default config file not available or script disabled"

	printTitle "How to fix it?"
	echo "Please check if the following file exists and is accessible:"
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
	echo "Please check if the following file exists and is accessible:"
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
	
else

	CONFIGFILE_NAME=$SCRIPT_NAME.conf
	CONFIGFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_NAME
	CONFIGFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_NAME

	for CONFIGFILE_FULLPATH in "$CONFIGFILE_FULLPATH_ETC" "$CONFIGFILE_FULLPATH_DIR"
	do
		if [ -f "$CONFIGFILE_FULLPATH" ]; then
		
			source "$CONFIGFILE_FULLPATH"
		fi
	done
fi


if [ $INSTALL_WEBSTACKUP = 1 ]; then

	printTitle "Installing prerequisites and other common packages"
	apt update -qq
	apt install software-properties-common gnupg2 dialog htop screen openssl -y -qq
	

	echo ""
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

	## Command: WEBSTACKUP
	if [ ! -e "/usr/bin/webstackup" ]; then
	
		ln -s ${INSTALL_DIR}script/zzwebstackup.sh /usr/bin/webstackup
	fi
	
	>"${AUTOGENERATED_DIR}variables.sh"
	
	
	echo ""
	echo "Creating a new user account (the deployer)..."
	id -u webstackup &>/dev/null || useradd webstackup --shell=/bin/false --create-home
	printMessage $(cat /etc/passwd | grep webstackup)
	
	
	echo "Generating an SSH key..."
	DEPLOYER_SSH_DIR=/home/webstackup/.ssh/
	mkdir -p "${DEPLOYER_SSH_DIR}"
	chown webstackup:webstackup "${DEPLOYER_SSH_DIR}" -R
	chmod u=rwX,go= "${DEPLOYER_SSH_DIR}" -R
	sudo -u webstackup -H ssh-keygen -t rsa -f "${DEPLOYER_SSH_DIR}id_rsa" -N ''
	chmod u=rX,go= "${DEPLOYER_SSH_DIR}" -R

	cd $WORKING_DIR_ORIGINAL
	sleep 5

else
	
	echo "Skipped (disabled in config)"
fi


## =========== NGINX ===========
printTitle "Installing Nginx"

if [ $INSTALL_NGINX = 1 ]; then

	echo "Remove previous version (if any)"
	apt purge --auto-remove nginx* -y -qq
	
	## Add Nginx key and repo
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
	apt update -qq && apt install nginx -y -qq

	## Create self-signed, bogus certificates (so that we can disable plain-HTTP completely)
	source "${INSTALL_DIR}script/https/self-sign-generate.sh"
	
	## Create dhparam file for HTTPS-enabling
	openssl dhparam -out "${AUTOGENERATED_DIR}dhparam.pem" 2048 > /dev/null

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
	
	## Move the original config outta way
	mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d_default_original_backup.conf

	## Upgrade all to HTTPS
	ln -s "${INSTALL_DIR}config/nginx/00_global_https_upgrade_all.conf" /etc/nginx/conf.d/

	## Disable the default website
	ln -s "${INSTALL_DIR}config/nginx/05_global_default_vhost_disable.conf" /etc/nginx/conf.d/
	
	## Activate some additional functionality
	ln -s "${INSTALL_DIR}config/nginx/02_global_http_level.conf" /etc/nginx/conf.d/
	
	systemctl restart nginx
	systemctl  --no-pager status nginx
	
	## Create home (if missing)
	WWW_DATA_HOME=/var/www/
	if [ ! -d "${WWW_DATA_HOME}" ]; then
	
		mkdir -p "${WWW_DATA_HOME}"
		chown www-data:www-data "${WWW_DATA_HOME}" -R
		chmod ug=rwX,o= "${WWW_DATA_HOME}" -R
	fi
	
	## Setting SetGUID on the directory
	# Any files created in the directory will have their group set to www-data
	chmod g+s "$WWW_DATA_HOME" -R
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi
exit

## =========== PHP ===========
printTitle "Installing PHP-CLI and PHP-FPM"

if [ $INSTALL_PHP = 1 ]; then
	
	echo "Remove previous version (if any)"
	apt purge --auto-remove php* -y -qq
	
	LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
	apt update -qq

	## mcrypt is discontinued since PHP 7.2
	apt install php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-common php${PHP_VER}-mbstring php${PHP_VER}-gd php${PHP_VER}-intl php${PHP_VER}-xml php${PHP_VER}-mysql php${PHP_VER}-zip php${PHP_VER}-curl -y -qq
	
	echo "PHP_INSTALLED_VERSION=${PHP_VER}" >> "${AUTOGENERATED_DIR}variables.sh"
	
	## Enable custom config
	ln -s  "${INSTALL_DIR}config/php/php-custom.ini" /etc/php/${PHP_VER}/fpm/conf.d/30-custom-${SCRIPT_NAME}.ini
	ln -s  "${INSTALL_DIR}config/php/php-custom.ini" /etc/php/${PHP_VER}/cli/conf.d/30-custom-${SCRIPT_NAME}.ini
	
	## Set timezone to Italy
	ln -s  "${INSTALL_DIR}config/php/timezone-italy.ini" /etc/php/${PHP_VER}/fpm/conf.d/30-timezone-italy-${SCRIPT_NAME}.ini
	ln -s  "${INSTALL_DIR}config/php/timezone-italy.ini" /etc/php/${PHP_VER}/cli/conf.d/30-timezone-italy-${SCRIPT_NAME}.ini
	
	## Use the default WEBSTACK.UP index.php as test from the default Nginx root
	ln -s "${INSTALL_DIR}config/php/index.php" "/usr/share/nginx/html"
	
	## Assign the nginx user to www-data group
	usermod -a -G www-data nginx
	
	systemctl restart nginx
	systemctl restart php${PHP_VER}-fpm
	systemctl  --no-pager status php${PHP_VER}-fpm
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== MySQL ===========
printTitle "Installing MySQL"

if [ $INSTALL_MYSQL = 1 ]; then
	
	echo "Remove previous version (if any)"
	apt purge --auto-remove mysql* -y -qq

	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5072E1F5

	touch /etc/apt/sources.list.d/webstackup.mysql.list
	echo "### webstackup" >> /etc/apt/sources.list.d/webstackup.mysql.list
	echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-${MYSQL_VER}" >> /etc/apt/sources.list.d/webstackup.mysql.list
	echo "deb-src http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-${MYSQL_VER}" >> /etc/apt/sources.list.d/webstackup.mysql.list
	echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-tools" >> /etc/apt/sources.list.d/webstackup.mysql.list
	
	echo ""
	printMessage "$(cat /etc/apt/sources.list.d/webstackup.mysql.list)"
	
	MYSQL_ROOT_PASSWORD="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 19)"
	debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"
	debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"
	debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select"

	apt update -qq
	apt install mysql-server mysql-client -y -qq
	
	## Enable legacy credentials plugin
	cp "${INSTALL_DIR}config/mysql/legacy_auth_plugin.cnf" "/etc/mysql/mysql.conf.d/legacy_auth_plugin.cnf"
	sudo chmod ugo=r "/etc/mysql/mysql.conf.d/legacy_auth_plugin.cnf"
	
	MYSQL_CREDENTIALS_DIR="/etc/turbolab.it/"
	MYSQL_CREDENTIALS_FULLPATH="${MYSQL_CREDENTIALS_DIR}mysql.conf"
	
	if [ ! -e "${MYSQL_CREDENTIALS_FULLPATH}" ]; then
	
		printTitle "Writing MySQL credentials to ${MYSQL_CREDENTIALS_FULLPATH}"
		mkdir -p "$MYSQL_CREDENTIALS_DIR"
		echo "MYSQL_USER='root'" > "${MYSQL_CREDENTIALS_FULLPATH}"
		echo "MYSQL_PASSWORD='$MYSQL_ROOT_PASSWORD'" >> "${MYSQL_CREDENTIALS_FULLPATH}"
		
		chown root:root "${MYSQL_CREDENTIALS_FULLPATH}"
		chmod u=r,go= "${MYSQL_CREDENTIALS_FULLPATH}"
	fi
	
	printMessage "$(cat "${MYSQL_CREDENTIALS_FULLPATH}")" 
	
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




## =========== Symfony ===========
printTitle "Installing Symfony"

if [ $INSTALL_SYMFONY = 1 ]; then
	
	wget https://get.symfony.com/cli/installer -O - | bash
	mv /root/.symfony/bin/symfony /usr/local/bin/symfony
	
	echo ""
	printMessage "$(symfony -V)"
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== zzupdate ===========
printTitle "Installing zzupdate"

if [ $INSTALL_ZZUPDATE = 1 ]; then

	curl -s https://raw.githubusercontent.com/TurboLabIt/zzupdate/master/setup.sh | sudo bash
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== zzmysqldump ===========
printTitle "Installing zzmysqldump"

if [ $INSTALL_ZZMYSQLDUMP = 1 ]; then

	curl -s https://raw.githubusercontent.com/TurboLabIt/zzmysqldump/master/setup.sh | sudo bash
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi

## =========== xdebug ===========
printTitle "Installing xdebug"

if [ $INSTALL_XDEBUG = 1 ]; then

	apt install php-xdebug -y -qq
	XDEBUG_CONFIG_FILE_FULLPATH="${INSTALL_DIR}config/php/xdebug.ini"
		
	ln -s "$XDEBUG_CONFIG_FILE_FULLPATH" /etc/php/${PHP_VER}/fpm/conf.d/30-xdebug-${SCRIPT_NAME}.ini
	ln -s "$XDEBUG_CONFIG_FILE_FULLPATH" /etc/php/${PHP_VER}/cli/conf.d/30-xdebug-${SCRIPT_NAME}.ini
	
	systemctl restart php${PHP_VER}-fpm
	sleep 5

else
	
	echo "Skipped (disabled in config)"
fi


## =========== Let's Encrypt ===========
printTitle "Installing Let's Encrypt"

if [ $INSTALL_LETSENCRYPT = 1 ]; then

	## Not yet available for Ubuntu 20.04 :-(
	#add-apt-repository ppa:certbot/certbot -y
	#apt update -qq
	apt install certbot -y -qq
	
	printMessage "$(certbot --version)"

	service cron restart
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== Postfix ===========
printTitle "Installing Postfix"

if [ $INSTALL_POSTFIX = 1 ]; then

	#DEBIAN_PRIORITY=low 
	apt install postfix mailutils opendkim opendkim-tools -y -qq
	
	adduser postfix opendkim
	
	mkdir /var/spool/postfix/opendkim
	chown opendkim:postfix /var/spool/postfix/opendkim
	
	sed -i -e 's|^UMask|#UMask|g' /etc/opendkim.conf
	sed -i -e 's|^Socket|#Socket|g' /etc/opendkim.conf
	echo "" >>  /etc/opendkim.conf
	echo "" >>  /etc/opendkim.conf
	echo "" >>  /etc/opendkim.conf
	cat "${INSTALL_DIR}config/opendkim/opendkim_to_be_appended.conf" >> /etc/opendkim.conf
	
	echo "" >>  /etc/postfix/main.cf
	echo "" >>  /etc/postfix/main.cf
	echo "" >>  /etc/postfix/main.cf
	cat "${INSTALL_DIR}config/opendkim/postfix_to_be_appended.conf" >> /etc/postfix/main.cf
	
	
	sed -i -e 's|^SOCKET=|#SOCKET=|g' /etc/default/opendkim
	echo "" >> /etc/default/opendkim
	echo "" >> /etc/default/opendkim
	echo "" >> /etc/default/opendkim
	cat "${INSTALL_DIR}config/opendkim/opendkim-default_to_be_appended.conf" >> /etc/default/opendkim
	
	mkdir -p /etc/opendkim/keys
	
	cp "${INSTALL_DIR}config/opendkim/TrustedHosts" /etc/opendkim/TrustedHosts
	cp "${INSTALL_DIR}config/opendkim/KeyTable" /etc/opendkim/KeyTable
	cp "${INSTALL_DIR}config/opendkim/SigningTable" /etc/opendkim/SigningTable
	
	chown opendkim:opendkim /etc/opendkim/ -R
	chmod ug=rwX,o=rX /etc/opendkim/ -R
	chmod u=rwX,og=X /etc/opendkim/keys -R
	
	systemctl restart postfix
	systemctl restart opendkim
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== NTP ===========
printTitle "Installing NTP client"

if [ $INSTALL_NTP = 1 ]; then

	apt install ntp -y -qq
	
	systemctl restart ntp
	systemctl  --no-pager status ntp
	
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== zzalias ===========
printTitle "Installing zzalias"

if [ $INSTALL_ZZALIAS = 1 ]; then

	curl -s https://raw.githubusercontent.com/TurboLabIt/zzalias/master/setup.sh | sudo bash
	sleep 5
	
else
	
	echo "Skipped (disabled in config)"
fi


## =========== The End ===========
printTitle "THE END"
echo "$((($(date +%s)-$TIME_START)/60)) min."

printTitle "Rebooting"
if [ "$REBOOT" = "1" ] && [ "$INSTALL_ZZUPDATE" = 1 ]; then

	while [ $REBOOT_TIMEOUT -gt 0 ]; do
	   echo -ne "$REBOOT_TIMEOUT\033[0K\r"
	   sleep 1
	   : $((REBOOT_TIMEOUT--))
	done
	zzupdate

elif [ "$REBOOT" = "1" ]; then

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
