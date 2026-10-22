#!/bin/sh
set -e

cat << EOF > /usr/local/etc/kismet_site.conf
gps=gpsd:host=127.0.0.1,port=2947
gpsmodelock=true
log_prefix=/runs/
httpd_username=${KISMET_USER}
httpd_password=${KISMET_PASSWORD}
EOF

exec /usr/local/bin/kismet --no-ncurses-wrapper -c "${KISMET_INTERFACE}"
