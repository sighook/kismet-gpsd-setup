#!/bin/sh
set -e

CONFIG_DIR="/home/kismon/.kismon"

mkdir -p "$CONFIG_DIR"
chown -R $KISMON_UID:$KISMON_GID "$CONFIG_DIR"

cat << EOF > "$CONFIG_DIR/kismon.conf"
{
  "servers": [
    {
      "uri": "http://127.0.0.1:2501",
      "username": "${KISMET_USER}",
      "password": "${KISMET_PASSWORD}",
      "connect": true,
      "id": 0
    }
  ],
  "window": {
    "maximized": false,
    "map_position": "widget"
  },
  "map": {
    "source": "openstreetmap",
    "update_marker_positions": true
  },
  "networks": {
    "autosave": 5,
    "num_backups": 5
  },
  "tracks": {
    "store": true
  }
}
EOF

exec /opt/kismon/bin/kismon
