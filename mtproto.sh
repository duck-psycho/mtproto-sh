#!/bin/bash
set -euo pipefail

CONTAINER_NAME="mtproto-proxy"

prompt() {
  local var_name=$1
  local prompt_text=$2
  local default=$3
  if [[ -e /dev/tty ]]; then
    read -r -e -p "$prompt_text" -i "$default" "$var_name" </dev/tty
  else
    printf -v "$var_name" '%s' "$default"
  fi
}

show_qrcode() {
  local proxy_url=$1
  if command -v curl &> /dev/null; then
    curl -fsSL https://qrcode.show -d "${proxy_url}"
  elif command -v wget &> /dev/null; then
    wget -qO- --post-data="${proxy_url}" https://qrcode.show
  else
    echo "Install curl or wget to display the QR code." >&2
  fi
}

echo "MTProto proxy(nineseconds/mtg) setup script."

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again: https://github.com/docker/docker-install"
    exit 1
fi

echo "If you don't understand the options, use the defaults."
prompt DOMAIN "Domain for TLS disguise (SNI): " "google.com"
prompt PORT "Host TCP port for MTProto: " "443"
prompt DNS_IP "IP address of DNS-over-HTTPS server: " "1.1.1.1"

docker pull -q nineseconds/mtg:2 >/dev/null
SECRET=$(docker run --rm nineseconds/mtg:2 generate-secret --hex "${DOMAIN}")

docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "Starting the proxy container. This may take a moment, please wait..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "${PORT}:443 \
  nineseconds/mtg:2 \
  simple-run -n "${DNS_IP}" -i prefer-ipv4 0.0.0.0:443 "${SECRET}" >/dev/null

ready=false
for _ in {1..30}; do
  if docker exec "${CONTAINER_NAME}" /mtg access /config.toml >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 0.2
done

if ! $ready; then
  echo "Container did not become ready in time." >&2
  docker logs "${CONTAINER_NAME}" >&2 || true
  exit 1
fi

PROXY_URL=$(docker exec "${CONTAINER_NAME}" /mtg access /config.toml | SECRET_HEX="${SECRET}" MTG_PORT="${PORT}" python3 -c '
import json, sys, os
from urllib.parse import urlencode

data = json.load(sys.stdin)
ip = None
for key in ("ipv4", "ipv6"):
    block = data.get(key)
    if isinstance(block, dict) and block.get("ip"):
        ip = block["ip"]
        break

if not ip:
    print("Could not detect public IP.", file=sys.stderr)
    sys.exit(1)

query = urlencode(
    {"server": ip, "port": os.environ["MTG_PORT"], "secret": os.environ["SECRET_HEX"]}
)

print("tg://proxy?" + query)
')

echo ""
echo "Telegram proxy link: ${PROXY_URL}"
echo ""
show_qrcode "${PROXY_URL}"
