#!/usr/bin/env bash
## Standard Magento cache-clearing routine by WEBSTACKUP
#
# How to:
# Copy this file to your project directory with:
#   curl -Lo script/cache-clear.sh https://raw.githubusercontent.com/TurboLabIt/webstackup/master/script/frameworks/magento/cache-clear-template.sh && sudo chmod u=rwx,go=rx script/cache-clear.sh
# You should then git commit your copy

SCRIPT_NAME=magento-cache-clear
fxHeader "🧹 Magento cache-clear"

showPHPVer

if [ -z "${MAGENTO_DIR}" ] || [ ! -d "${MAGENTO_DIR}" ]; then
  fxCatastrophicError "📁 MAGENTO_DIR not set"
fi

cd "$MAGENTO_DIR"

fxTitle "Stopping services.."
sudo nginx -t && sudo service nginx stop && sudo service ${PHP_FPM} stop

sudo rm -rf \
  "pub/static/frontend/" \
  "pub/static/adminhtml/" \
  "pub/static/_requirejs" \
  "pub/static/deployed_version.txt" \
  "var/cache/" \ 
  "var/page_cache/" \
  "generated/" \ 
  "var/view_preprocessed/" \
  "var/session/" \
  "var/di/"
              
wsuMage setup:di:compile

wsuMage setup:static-content:deploy --area adminhtml it_IT en_US -f
wsuMage setup:static-content:deploy -t $@ -f

wsuMage cache:flush

sudo chown ${EXPECTED_USER}:www-data . -R
sudo find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
sudo find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

fxTitle "Restarting services.."
sudo nginx -t && sudo service ${PHP_FPM} restart && sudo service nginx restart
