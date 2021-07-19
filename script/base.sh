#!/bin/bash

## Install directory
WEBSTACKUP_INSTALL_DIR_PARENT=/usr/local/turbolab.it/
WEBSTACKUP_INSTALL_DIR=${WEBSTACKUP_INSTALL_DIR_PARENT}webstackup/
WEBSTACKUP_AUTOGENERATED_DIR=${WEBSTACKUP_INSTALL_DIR}autogenerated/

## Absolute path to this script, e.g. /home/user/bin/foo.sh
WEBSTACKUP_SCRIPT_FULLPATH=$(readlink -f "$0")

## Absolute path this script is in, thus /home/user/bin
WEBSTACKUP_SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

if [ -z "$SCRIPT_FULLPATH" ]; then

  ## Current directory to cd back to at the end
  INITIAL_DIR=$(pwd)

  ## Absolute path to this script, e.g. /home/user/bin/foo.sh
  SCRIPT_FULLPATH=$(readlink -f "$0")

  ## Absolute path this script is in, thus /home/user/bin
  SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/
  
  PROJECT_DIR=$(readlink -m "${SCRIPT_DIR}..")/
  WEBROOT_DIR=${PROJECT_DIR}public/
fi

if [ -z "$TIME_START" ]; then

  TIME_START="$(date +%s)"
fi

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


lockCheck ()
{
  LOCKFILE=$1.lock
  if [ -f $LOCKFILE ]; then
    catastrophicError "Lockfile detected. It looks like this script is already running
To override:
sudo rm -f \"$LOCKFILE\""

    echo ""
    cat "$1.lock"

    echo ""
    exit
  fi

  echo "$1.sh lock file." > "$LOCKFILE"
  echo "File created $(date)" >> "$LOCKFILE"
}


removeLock ()
{
  rm -f "$1.lock"
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
