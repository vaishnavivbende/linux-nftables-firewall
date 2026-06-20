#!/bin/bash

NFT="/usr/sbin/nft"

# Exit immediately if any command fails
set -e

# update dynamic IP vars
/etc/firewall/updateIP.sh

# build a temporary combined ruleset
TMPFILE=$(mktemp)

# Ensure temp file is cleaned up even if script fails
trap "rm -f $TMPFILE" EXIT

/bin/cat /etc/firewall/nft-vars.nft \
         /etc/firewall/setup-tables.nft \
         /etc/firewall/localhost-policy.nft \
         /etc/firewall/connectionstate-policy.nft \
         /etc/firewall/invalid-policy.nft \
         /etc/firewall/dns-policy.nft \
         /etc/firewall/ssh-policy.nft \
         /etc/firewall/tcpclient-policy.nft \
         /etc/firewall/icmp-policy.nft \
         /etc/firewall/log-policy.nft > "$TMPFILE"

# flush
$NFT flush ruleset

# load everything in ONE parser session
$NFT -f "$TMPFILE"

echo "Firewall loaded successfully at $(date)"

exit 0
