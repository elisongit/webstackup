#!/bin/bash

#### Webstackup directory
WEBSTACKUP_INSTALL_DIR_PARENT=/usr/local/turbolab.it/
WEBSTACKUP_INSTALL_DIR=${WEBSTACKUP_INSTALL_DIR_PARENT}webstackup/
WEBSTACKUP_AUTOGENERATED_DIR=${WEBSTACKUP_INSTALL_DIR}autogenerated/
WEBSTACKUP_CONFIG_DIR=${WEBSTACKUP_INSTALL_DIR}config/
WEBSTACKUP_SCRIPT_DIR=${WEBSTACKUP_INSTALL_DIR}script/

#### Calling script paths (it works only when it's called as `source base.sh`)
## Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT_FULLPATH=$(readlink -f "$0")

## Absolute path this script is in, thus /home/user/bin
SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

##
INITIAL_DIR=$(pwd)
PROJECT_DIR=$(readlink -m "${SCRIPT_DIR}..")/
WEBROOT_DIR=${PROJECT_DIR}public/

## Hostname
HOSTNAME="$(hostname)"

if [ -z "$TIME_START" ]; then
  TIME_START="$(date +%s)"
fi

DOWEEK="$(date +'%u')"

## Header (green)
WEBSTACKUP_FRAME="O===========================================================O"
printHeader ()
{
  STYLE='\033[42m'
  RESET='\033[0m'

  echo ""
  echo -n -e $STYLE
  echo ""
  echo "$WEBSTACKUP_FRAME"
  echo " --> $1 - $(date) on $(hostname)"
  echo "$WEBSTACKUP_FRAME"
  echo -e $RESET
}


function printTheEnd ()
{
  echo ""
  echo "The End"
  echo $(date)
  
  if [ ! -z "$TIME_START" ]; then
    echo "$((($(date +%s)-$TIME_START)/60)) min."
  fi
  
  echo "$WEBSTACKUP_FRAME"
  cd $INITIAL_DIR
  exit
}


function catastrophicError ()
{
  STYLE='\033[41m'
  RESET='\033[0m'

  echo ""
  echo -n -e $STYLE
  echo "vvvvvvvvvvvvvvvvvvvv"
  echo "Catastrophic error!!"
  echo "^^^^^^^^^^^^^^^^^^^^"
  echo "$1"
  echo -e $RESET
  
  printTheEnd
}


rootCheck ()
{
  if ! [ $(id -u) = 0 ]; then
    catastrophicError "This script must run as ROOT"
  fi
}


devOnlyCheck ()
{
  if [ "$APP_ENV" != "dev" ]; then
    catastrophicError "This script is for DEV only!"
  fi
}


lockCheck ()
{
  local LOCKFILE=${1}.lock
  if [ -f $LOCKFILE ]; then
    catastrophicError "Lockfile detected. It looks like this script is already running
To override:
sudo rm -f \"$LOCKFILE\""

    echo ""
    cat "$1.lock"

    echo ""
    exit
  fi

  echo "${1}.sh lock file." > "$LOCKFILE"
  echo "File created $(date)" >> "$LOCKFILE"
  printMessage "Lock file created in $LOCKFILE"
}


removeLock ()
{
  local LOCKFILE=${1}.lock
  rm -f "${LOCKFILE}"
  printMessage "${LOCKFILE} deleted"
}


function printTitle ()
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


function printMessage ()
{
  STYLE='\033[45m'
  RESET='\033[0m'

  echo ""
  echo -n -e $STYLE
  echo "$1"
  echo -e $RESET
  echo ""
}


printLightWarning ()
{
  STYLE='\033[33m'
  RESET='\033[0m'

  echo ""
  echo -n -e $STYLE
  echo "$1"
  echo -e $RESET
  echo ""
}


if [ -r "${WEBSTACKUP_AUTOGENERATED_DIR}variables.sh" ]; then
  source "${WEBSTACKUP_AUTOGENERATED_DIR}variables.sh"
fi


if [ -r "/etc/turbolab.it/mysql.conf" ]; then
  source "/etc/turbolab.it/mysql.conf"
fi


INSTALLED_RAM=$(awk '/MemFree/ { printf "%.3f \n", $2/1024/1024 }' /proc/meminfo)
INSTALLED_RAM="${INSTALLED_RAM//.}"

GIT_BRANCH=$(git -C $PROJECT_DIR branch | grep \* | cut -d ' ' -f2-)

if [ -f "${PROJECT_DIR}env" ]; then

  APP_ENV=$(head -n 1 ${PROJECT_DIR}env)

elif [ "$GIT_BRANCH" = "master" ]; then

  APP_ENV=prod
  
elif [ "$GIT_BRANCH" = "staging" ]; then

  APP_ENV=staging
  
elif [ "$GIT_BRANCH" = "dev" ]; then

  APP_ENV=dev

fi


function checkExecutingUser ()
{
  ## Current user
  CURRENT_USER=$(whoami)

  if [ "$CURRENT_USER" != "$1" ]; then

    echo "vvvvvvvvvvvvvvvvvvvv"
    echo "Catastrophic error!!"
    echo "^^^^^^^^^^^^^^^^^^^^"
    echo "Wrong user: please run this script as: "
    echo "sudo -u $1 -H bash \"$SCRIPT_FULLPATH\""

    printTheEnd
  fi
}


function browsePage
{
    echo "Browsing ##${1}##..."
    curl --insecure --location --show-error --write-out "%{http_code}" "${1}"
    echo
}


function zzcache()
{
  ZZCACHE_INITIAL_DIR=$(pwd)
  cd "$PROJECT_DIR"
  XDEBUG_MODE=off symfony console cache:clear
  cachetool opcache:reset --fcgi=/run/php/${PHP_FPM}.sock
  cd "$ZZCACHE_INITIAL_DIR"
}


function flushOpcache()
{
  echo "flushOpcache is a TO DO"
}


function browse()
{
  BROWSEURL=$1
  echo ${BROWSEURL}
  curl --insecure --location --silent --show-error --output /dev/null --write-out "%{http_code}" ${BROWSEURL}
  echo
}
