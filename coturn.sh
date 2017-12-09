#!/bin/bash

# Discover public and private IP for this instance
PUBLIC_IPV4="$(curl -4 icanhazip.com)"
PRIVATE_IPV4="$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"

PORT=${PORT:-3478}
ALT_PORT=${PORT:-3479}

TLS_PORT=${TLS:-5349}
TLS_ALT_PORT=${PORT:-5350}

MIN_PORT=${MIN_PORT:-49152}
MAX_PORT=${MAX_PORT:-65535}

TURNSERVER_CONFIG=/etc/coturn/turnserver.conf

cat <<EOF > ${TURNSERVER_CONFIG}.default
# https://github.com/coturn/coturn/blob/master/examples/etc/coturn.conf
listening-port=${PORT}
min-port=${MIN_PORT}
max-port=${MAX_PORT}
EOF

if [ "${PUBLIC_IPV4}" != "${PRIVATE_IPV4}" ]; then
  echo "external-ip=${PUBLIC_IPV4}/${PRIVATE_IPV4}" >> ${TURNSERVER_CONFIG}.default
else
  echo "external-ip=${PUBLIC_IPV4}" >> ${TURNSERVER_CONFIG}.default
fi

if [ -n "${JSON_CONFIG}" ]; then
  echo "${JSON_CONFIG}" | jq -r '.config[]' >> ${TURNSERVER_CONFIG}.default
fi

if [ -n "$SSL_CERTIFICATE" ]; then
  echo "$SSL_CA_CHAIN" > /etc/coturn/turnserver_cert.pem
  echo "$SSL_CERTIFICATE" >> /etc/coturn/turnserver_cert.pem
  echo "$SSL_PRIVATE_KEY" > /etc/coturn/turnserver_pkey.pem

  cat <<EOT >> ${TURNSERVER_CONFIG}.default
tls-listening-port=${TLS_PORT}
alt-tls-listening-port=${TLS_ALT_PORT}
cert=/etc/coturn/turnserver_cert.pem
pkey=/etc/coturn/turnserver_pkey.pem
EOT

fi

envsubst < ${TURNSERVER_CONFIG}.default > ${TURNSERVER_CONFIG}

exec /usr/bin/turnserver
