#!/bin/bash
echo ""

source "/usr/local/webstackup/script/base.sh"
printHeader "Generate a HTTPS certificate (self-signed)"
rootCheck


## New website data from CLI (if any)
SELFSIGN_DOMAIN=$1

while [ -z "$SELFSIGN_DOMAIN" ]
do
	echo ""
	read -p "Please provide the website domain (no-www! E.g.: turbolab.it) for this certificate: " SELFSIGN_DOMAIN  < /dev/tty
	
	if [ -z "${SELFSIGN_DOMAIN}" ]; then
	
		continue
	fi
	
	printMessage "Domain: $SELFSIGN_DOMAIN"
	
	SELFSIGN_DOMAIN_2ND=$(echo "$SELFSIGN_DOMAIN" |  cut -d '.' -f 1)
	SELFSIGN_DOMAIN_TLD=$(echo "$SELFSIGN_DOMAIN" |  cut -d '.' -f 2)
	
	if [ -z "${SELFSIGN_DOMAIN_2ND}" ] || [ -z "${SELFSIGN_DOMAIN_TLD}" ] || [ "${SELFSIGN_DOMAIN_2ND}" == "${SELFSIGN_DOMAIN_TLD}" ]; then
	
		SELFSIGN_DOMAIN=		
		printMessage "Invalid domain! Try again"
		continue
	fi
	
	printMessage "OK, this website domain looks valid!"

done


## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=898470
#touch "$HOME/.rnd"

printMessage "Copy the configuration template..."
SELFSIGN_CONFIG=${WEBSTACKUP_AUTOGENERATED_DIR}https-self-sign-${SELFSIGN_DOMAIN}.conf
cp "/usr/local/turbolab.it/webstackup/config/https/self-sign-template.conf" "$SELFSIGN_CONFIG"

printMessage "Replacing localhost with ${SELFSIGN_DOMAIN}..."
sed -i "s/localhost/${SELFSIGN_DOMAIN}/g" "$SELFSIGN_CONFIG"


SELFSIGN_KEY=${WEBSTACKUP_AUTOGENERATED_DIR}openssl-private-key.pem
if [ ! -f "${SELFSIGN_KEY}" ]; then

	printMessage "Generating the private key..."
	openssl genrsa -out "${SELFSIGN_KEY}"
	
else

	printMessage "Private key found"
fi


printMessage "Generating the certificate..."
openssl req -x509 -out "${WEBSTACKUP_AUTOGENERATED_DIR}https-${SELFSIGN_DOMAIN}.crt" -key ${SELFSIGN_KEY} \
	-days 3650 \
	-new -nodes -sha256 \
	-subj "/CN=${SELFSIGN_DOMAIN}" \
	-extensions EXT -config "$SELFSIGN_CONFIG"

rm -f "$SELFSIGN_CONFIG"
		

printMessage "Trusting my new cert (Firfox only)..."
apt install libnss3-tools -y
killall firefox
for USER_HOME in /home/*; do

	for FIREFOX_DIR in ${USER_HOME}/.mozilla/firefox/*; do

		if ls ${FIREFOX_DIR}/places.sqlite &>/dev/null; then
		
			echo "Found! $FIREFOX_DIR"
			certutil -D -n "${SELFSIGN_DOMAIN}" -d sql:"${FIREFOX_DIR}" >/dev/null 2>&1
			certutil -A -n "${SELFSIGN_DOMAIN}" -t "TC,," -i "${WEBSTACKUP_AUTOGENERATED_DIR}https-${SELFSIGN_DOMAIN}.crt" -d sql:"${FIREFOX_DIR}"
			certutil -d sql:"${FIREFOX_DIR}" -L
		fi
	done

done

printMessage "Bogus HTTPS certificate ready"
