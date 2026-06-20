#!/bin/bash

set -e

INTERFACE="wlp2s0"
VARS_FILE="/etc/firewall/nft-vars.nft"

# Get IPv4 address
ip4=$(ip -4 -o addr show dev "$INTERFACE" | awk '{print $4}' | cut -d/ -f1)

# Validate IPv4 was found
if [[ -z "$ip4" ]]; then
    echo "ERROR: Could not detect IPv4 address on $INTERFACE"
    exit 1
fi

# Get correct IPv4 subnet (network/prefix)
ip4_subnet=$(ip -4 route show dev "$INTERFACE" | awk '/proto kernel/ {print $1; exit}')

if [[ -z "$ip4_subnet" ]]; then
    ip4_subnet=$(ip -4 addr show dev "$INTERFACE" | awk '/inet / {print $2; exit}')
fi

# Validate IPv4 subnet was found
if [[ -z "$ip4_subnet" ]]; then
    echo "ERROR: Could not detect IPv4 subnet on $INTERFACE"
    exit 1
fi

# Get global IPv6 address (ignore fe80 and temporary)
ip6=$(ip -6 -o addr show dev "$INTERFACE" \
        | awk '/inet6/ && !/fe80/ && !/temporary/ {print $4}' \
        | cut -d/ -f1 | head -n 1)

# Get correct IPv6 subnet
ip6_subnet=$(ip -6 route show dev "$INTERFACE" \
        | awk '$1 ~ /^[0-9a-fA-F:]+\/[0-9]+$/ && !/fe80/ {print $1}' \
        | head -n 1)

if [[ -z "$ip6" ]]; then
    ip6="::"
    ip6_subnet="::/128"
fi

# Remove old dynamic definitions
sed -i '/^define externalIP = /d' "$VARS_FILE"
sed -i '/^define externalSubnet = /d' "$VARS_FILE"
sed -i '/^define externalIPv6 = /d' "$VARS_FILE"
sed -i '/^define externalIPv6Subnet = /d' "$VARS_FILE"

# Insert new values WITHOUT QUOTES
{
    echo "define externalIP = $ip4"
    echo "define externalSubnet = $ip4_subnet"
    echo "define externalIPv6 = $ip6"
    echo "define externalIPv6Subnet = $ip6_subnet"
    echo ""
} | cat - "$VARS_FILE" > "${VARS_FILE}.tmp" && mv "${VARS_FILE}.tmp" "$VARS_FILE"

echo "Updated:"
echo "IPv4 Address:     $ip4"
echo "IPv4 Subnet:      $ip4_subnet"
echo "IPv6 Address:     $ip6"
echo "IPv6 Subnet:      $ip6_subnet"
