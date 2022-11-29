#!/usr/bin/env bash
### AUTOMATIC ELASTICSEARCH INSTALLER BY WEBSTACK.UP
# https://github.com/TurboLabIt/webstackup/tree/master/script/elasticsearch/install.sh
#
# sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/webstackup/master/script/elasticsearch/install.sh?$(date +%s) | sudo bash
#
# Based on: 

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "💿 ElasticSearch installer"
rootCheck

fxTitle "Removing any old previous instance..."
apt purge --auto-remove elasticsearch* -y
rm -rf /etc/elasticsearch

## installing/updating WSU
WSU_DIR=/usr/local/turbolab.it/webstackup/
if [ ! -f "${WSU_DIR}setup.sh" ]; then
  curl -s https://raw.githubusercontent.com/TurboLabIt/webstackup/master/setup.sh?$(date +%s) | sudo bash
fi

source "${WSU_DIR}script/base.sh"

fxTitle "Importing the signing key..."
curl https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor | sudo tee /usr/share/keyrings/elasticearch-keyring.gpg >/dev/null

fxTitle "Adding the repo to APT..."
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elasticsearch.list

fxTitle "Set up repository pinning to prefer our packages over distribution-provided ones..."
echo -e "Package: *\nPin: origin artifacts.elastic.co\nPin: release o=elasticsearch\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99elasticsearch

fxTitle "apt install elasticsearch..."
apt update -qq
apt install elasticsearch -y

fxTitle "Linking a base config..."
fxLink "${WEBSTACKUP_CONFIG_DIR}elasticsearch/jvm.options" /etc/elasticsearch/jvm.options.d/

fxTitle "Service management..."
systemctl enable elasticsearch
service elasticsearch restart
systemctl --no-pager status elasticsearch

fxTitle "Testing..."
curl -X GET 'http://localhost:9200'

fxTitle "Netstat..."
ss -lpt | grep -i 'java\|elastic'

fxEndFooter
