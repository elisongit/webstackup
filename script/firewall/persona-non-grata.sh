#!/bin/bash
clear

source "/usr/local/turbolab.it/webstackup/script/base.sh"
printHeader "🛡️ persona-non-grata"
rootCheck


printTitle "Checking/installing packages...."

if [ -z "$(command -v ufw)" ] || [ -z "$(command -v ipset)" ]; then

  printMessage "Installing ufw and ipset..."
  apt update
  apt install ufw ipset -y
  
else

  printMessage "✔ ufw and ipset are already installed"
  
  printTitle "Removing previous rules and disable the firewall..."
  ufw --force reset
  
  printTitle "🧹 Removing backup file..."
  rm -f /etc/ufw/user.rules.* /etc/ufw/before.rules.* /etc/ufw/after.rules.*
  rm -f /etc/ufw/user6.rules.* /etc/ufw/before6.rules.* /etc/ufw/after6.rules.*

fi


printTitle "🚪 Opening some common ports via ufw..."

printMessage "🐧 Allow SSH (before I lock myself out one more time)..."
ufw allow 22,222/tcp

printMessage "🚢 Allow connections from Docker containers..."
ufw allow from 172.17.0.0/16 to any

printMessage "📁 Allow FTP/FTPS (if installed)"
ufw allow 20,21,990,2121:2221/tcp

printMessage "💌 Allow SMTP..."
ufw allow 25/tcp

printMessage "🌎 Allow HTTP(s)..."
ufw allow 80,443/tcp


printTitle "🔥🔥 Shields up! Activating the firewall..."
ufw --force enable 
ufw status | grep -v v6


printTitle "⏬ Downloading IP block list..."
mkdir -p "${WEBSTACKUP_AUTOGENERATED_DIR}"
IP_BLACKLIST_FULLPATH=${WEBSTACKUP_AUTOGENERATED_DIR}persona-non-grata.txt
curl -Lo "${IP_BLACKLIST_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/firewall/persona-non-grata.txt


printTitle "🧹 Cleaning up the log file..."
PNG_IP_LOG_FILE=${WEBSTACKUP_AUTOGENERATED_DIR}persona-non-grata.log
date +"%Y-%m-%d %T" > "${PNG_IP_LOG_FILE}"

printTitle "🧹 Cleaning up previous persona-non-grata iptables rule..."
PNG_IPTABLES_RULE="INPUT -m set --match-set PersonaNonGrata src -j DROP"

iptables -C $PNG_IPTABLES_RULE &> /dev/null
PNG_IPTABLES_RULE_EXIST="$?"
if [ "$PNG_IPTABLES_RULE_EXIST" == "0" ]; then

  printMessage "iptables rule for PersonaNonGrata found. Removing..."
  iptables -D $PNG_IPTABLES_RULE
	
else

  printMessage "✔ iptables rule for PersonaNonGrata NOT found"
fi

printTitle "🧹 Cleaning up previous persona-non-grata ipset set..."
ipset destroy PersonaNonGrata

printTitle "☀ Creating new persona-non-grata ipset set..."
ipset create PersonaNonGrata nethash

printTitle "🧱 Building ipset from file..."
while read -r line || [[ -n "$line" ]]; do
  FIRSTCHAR="${line:0:1}"
  if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then
    echo "Add: $line" >> "${PNG_IP_LOG_FILE}"
    ipset add PersonaNonGrata $line
  fi	
done < "$IP_BLACKLIST_FULLPATH"

printTitle "🧱 Done!"
ipset list PersonaNonGrata | head -n 7
echo "...."

printTitle "🔗 Hooking it up on iptables..."
iptables -I $PNG_IPTABLES_RULE

printMessage "✅ persona-non-grata is done"
iptables -L -n | grep --color=always -B5 -A2 -i PersonaNonGrata
echo "..."
echo ""
ufw status | grep -v v6

printTitle "Need the log?"
printMessage "nano ${PNG_IP_LOG_FILE}"
