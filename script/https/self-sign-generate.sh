#!/bin/bash
echo ""

## Script name
SCRIPT_NAME=self-sign-generate

## Title and graphics
FRAME="O===========================================================O"
echo "$FRAME"
echo " Generate self-signed, bogus certificate WEBSTACK.UP - $(date)"
echo "$FRAME"

## Enviroment variables
TIME_START="$(date +%s)"
DOWEEK="$(date +'%u')"
HOSTNAME="$(hostname)"

SSL_DIR=${AUTOGENERATED_DIR}


## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=898470
#touch "$HOME/.rnd"


echo "Generating the certificate..."
openssl req -x509 -out ${SSL_DIR}ssl_certificate.crt -keyout ${SSL_DIR}ssl_certificate_key.key \
	-days 3650 \
	-newkey rsa:2048 -nodes -sha256 \
	-subj '/CN=localhost' -extensions EXT -config <( \
		printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
		
		
echo "Trusting my own CA (Firfox only)..."
sudo apt install libnss3-tools -y
for FIREFOX_DIR in /home/$(logname)/.mozilla/firefox/*; do

	if ls ${FIREFOX_DIR}/places.sqlite &>/dev/null; then
	
		echo "Found! $FIREFOX_DIR"
		certutil -A -n "webstackup" -t "TC,," -i "${AUTOGENERATED_DIR}ssl_certificate.crt" -d sql:"${FIREFOX_DIR}"
		certutil -d sql:"${FIREFOX_DIR}" -L
	fi
done


##
printMessage "Bogus HTTPS certificate ready"
printMessage "$(ls -la "${AUTOGENERATED_DIR}" | grep ssl_certificate)"


## =========== The End ===========
printTitle "Time took"
echo "$((($(date +%s)-$TIME_START)/60)) min."

printTitle "The End"
echo $(date)
echo "$FRAME"
