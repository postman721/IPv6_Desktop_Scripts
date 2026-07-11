#!/bin/bash
echo "=== Persistent UFW settings ==="
sudo grep -E \
'^[[:space:]]*(IPV6|DEFAULT_(INPUT|OUTPUT|FORWARD)_POLICY)[[:space:]]*=' \
/etc/default/ufw

echo
echo "=== Active UFW policy ==="
sudo ufw status verbose

echo
echo "=== Explicit UFW rules ==="
sudo ufw status numbered

echo
echo "=== Global IPv6 addresses ==="
ip -6 -o address show scope global |
    awk '{split($4, address, "/"); print address[1]}' |
    sort -u

echo
echo "=== IP forwarding ==="
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding

echo
echo "=== Listening services ==="
sudo ss -lntup
