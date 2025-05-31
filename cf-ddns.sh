#!/bin/bash
set -eu pipefail

IP_ADDRESS=$(curl -s --fail https://ifconfig.io || true)

if [[ -z "$IP_ADDRESS" ]]; then
  echo "ts=$(date -Is) level=error msg=\"Failed to retrieve IP address\"" >&2
  exit 1
fi

JSON_PAYLOAD=$(cat <<EOF
{
  "comment": "Reassigned by $(uname -n)",
  "content": "$IP_ADDRESS",
  "name": "$DNS_NAME",
  "proxied": ${PROXIED:-true},
  "ttl": ${TTL:-3600},
  "type": "A"
}
EOF
)

RESPONSE=$(curl -s --fail -X PUT \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -d "$JSON_PAYLOAD" || true)

# If you don't want log info on the journal, comment the following out
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "ts=$(date -Is) level=info msg=\"DNS update successful\" ip=\"$IP_ADDRESS\" dns_name=\"$DNS_NAME\" response=\"$RESPONSE\""
else
  echo "ts=$(date -Is) level=error msg=\"DNS update failed\" ip=\"$IP_ADDRESS\" dns_name=\"$DNS_NAME\" response=\"$RESPONSE\"" >&2
  exit 1
fi
