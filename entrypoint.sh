#!/usr/bin/env bash
set -e

echo "🔄 Applying ThingsBoard 3.9 → 4.0 migrations…"
exec /usr/share/thingsboard/bin/install/upgrade.sh

# when upgrade.sh completes, start ThingsBoard
echo "▶️ Starting ThingsBoard 4.0…"
exec java -jar /usr/share/thingsboard/bin/thingsboard.jar
