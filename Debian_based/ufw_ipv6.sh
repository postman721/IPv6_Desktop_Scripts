#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

# Require root.
if (( ${EUID:-$(id -u)} != 0 )); then
    echo "Run with sudo: sudo bash ufw_ipv6.sh"
    exit 1
fi

# Check required commands and suggest Debian/Ubuntu packages.
declare -A PACKAGES=(
    [curl]="curl"
    [ufw]="ufw"
    [ip]="iproute2"
    [ss]="iproute2"
    [tee]="coreutils"
)

MISSING=()

for COMMAND in "${!PACKAGES[@]}"; do
    command -v "$COMMAND" >/dev/null 2>&1 ||
        MISSING+=("${PACKAGES[$COMMAND]}")
done

if ((${#MISSING[@]})); then
    mapfile -t MISSING < <(printf '%s\n' "${MISSING[@]}" | sort -u)

    echo "Install the missing packages:"
    echo "  sudo apt update"
    echo "  sudo apt install ${MISSING[*]}"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT="/var/log/ufw-desktop-report-${TIMESTAMP}.log"
UFW_CONFIG="/etc/default/ufw"

# Display output and save it to a root-only report.
touch "$REPORT"
chmod 600 "$REPORT"
exec > >(tee -a "$REPORT") 2>&1

echo "UFW desktop security report"
echo "Date: $(date --iso-8601=seconds)"
echo "Host: $(hostname)"
echo

# Test public IPv6 connectivity.
echo "Testing IPv6..."

if IPV6=$(curl -6fsSL --connect-timeout 5 --max-time 15 \
    https://www.whatismyip.net/ip/); then

    IPV6=$(printf '%s' "$IPV6" | tr -d '[:space:]')

    if [[ $IPV6 == *:* ]]; then
        echo "IPv6 is working."
        echo "Public IPv6: $IPV6"
    else
        echo "The service responded, but did not return an IPv6 address."
    fi
else
    echo "IPv6 connectivity test failed."
fi

echo

# Back up the UFW settings file.
cp -a "$UFW_CONFIG" "${UFW_CONFIG}.backup-${TIMESTAMP}"

# Enable IPv6 filtering in UFW.
if grep -qE '^[[:space:]]*IPV6=' "$UFW_CONFIG"; then
    sed -i -E \
        's/^[[:space:]]*IPV6[[:space:]]*=.*/IPV6=yes/' \
        "$UFW_CONFIG"
else
    printf '\nIPV6=yes\n' >> "$UFW_CONFIG"
fi

# Secure desktop defaults.
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

# Enable low-volume firewall logging.
ufw logging low

# Enable the firewall.
ufw --force enable

echo
echo "UFW status:"
ufw status verbose

echo
echo "Listening network services:"
ss -lntup

echo
echo "Local IPv6 addresses:"
ip -6 address show scope global

echo
echo "Report saved to:"
echo "  $REPORT"

echo
echo "Read recent UFW logs with:"
echo "sudo journalctl -k | grep UFW"



#########################
# Run with:

# chmod 700 ufw_ipv6.sh
# sudo bash ufw_ipv6.sh
# Check status: sudo ufw status verbose
# Check your ipv6 address from cli: ip -6 address show scope global
