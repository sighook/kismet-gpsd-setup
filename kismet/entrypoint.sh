#!/bin/sh
set -e

cat << EOF > /etc/kismet/kismet_site.conf
gps=gpsd:host=127.0.0.1,port=2947
gpsmodelock=true
log_prefix=/runs/
httpd_username=${KISMET_USER}
httpd_password=${KISMET_PASSWORD}
EOF

exec /usr/bin/kismet --no-ncurses-wrapper -c "${KISMET_INTERFACE}"
