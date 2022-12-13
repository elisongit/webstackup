#!/usr/bin/env bash
## Standard Symfony cache-clearing routine by WEBSTACKUP
#
# How to:
#
# 1. set `PROJECT_FRAMEWORK=symfony` in your project `script_begin.sh`
#
# 1. Copy the "starter" script to your project directory with:
#   curl -Lo scripts/cache-clear.sh https://raw.githubusercontent.com/TurboLabIt/webstackup/master/my-app-template/scripts/cache-clear.sh && sudo chmod u=rwx,go=rx scripts/cache-clear.sh
#
# 1. You should now git commit your copy
#
# Tip: after the first `deploy.sh`, you can `zzcache` directly

fxHeader "📐🧹 Symfony cache-clear"

showPHPVer

if [ -z "${PROJECT_DIR}" ] || [ ! -d "${PROJECT_DIR}" ]; then
  fxCatastrophicError "📁 PROJECT_DIR not set"
fi

if [ "$1" = "fast" ]; then
  FAST_CACHE_CLEAR=1
fi

cd "$PROJECT_DIR"

if [ -z "${FAST_CACHE_CLEAR}" ]; then

  fxTitle "⚙️ Stopping services.."
  sudo nginx -t && sudo service nginx stop && sudo service ${PHP_FPM} stop

  fxTitle "🧹 Removing Symfony cache folder..."
  sudo rm -rf "${PROJECT_DIR}var/cache"
  
  fxTitle "🚚 Migrating..."
  wsuSymfony console doctrine:migrations:migrate --no-interaction

else

  fxTitle "📐 Symfony cache folder NOT removed (fast mode)"
fi

fxTitle "🌊 Symfony cache:clear..."
wsuSymfony console cache:clear

if [ -z "${FAST_CACHE_CLEAR}" ]; then

  fxTitle "⚙️ Restarting services.."
  sudo nginx -t && sudo service ${PHP_FPM} restart && sudo service nginx restart

else

  fxTitle "🌊 PHP OPcache clear..."
  wsuOpcacheClear
fi
