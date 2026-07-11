#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

# Require root.
if (( ${EUID:-$(id -u)} != 0 )); then
    echo "Run with sudo:"
    echo "  sudo bash ufw_ipv6.sh"
    exit 1
fi

# Check required commands and suggest Debian/Ubuntu packages.
declare -A PACKAGES=(
    [awk]="gawk"
    [cp]="coreutils"
    [date]="coreutils"
    [grep]="grep"
    [hostname]="hostname"
    [ip]="iproute2"
    [mktemp]="coreutils"
    [sed]="sed"
    [ss]="iproute2"
    [tee]="coreutils"
    [ufw]="ufw"
)

MISSING=()

for COMMAND in "${!PACKAGES[@]}"; do
    if ! command -v "$COMMAND" >/dev/null 2>&1; then
        MISSING+=("${PACKAGES[$COMMAND]}")
    fi
done

if ((${#MISSING[@]})); then
    mapfile -t MISSING < <(
        printf '%s\n' "${MISSING[@]}" | sort -u
    )

    echo "Install the missing packages:"
    echo "  sudo apt update"
    echo "  sudo apt install ${MISSING[*]}"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT="/var/log/ufw-desktop-report-${TIMESTAMP}.log"
UFW_CONFIG="/etc/default/ufw"
UFW_BACKUP="${UFW_CONFIG}.backup-${TIMESTAMP}"

# Make sure the UFW configuration exists.
if [[ ! -f "$UFW_CONFIG" ]]; then
    echo "UFW configuration not found: $UFW_CONFIG"
    exit 1
fi

# Display output and save it to a root-only report.
touch "$REPORT"
chmod 600 "$REPORT"
exec > >(tee -a "$REPORT") 2>&1

echo "UFW desktop security report"
echo "Date: $(date --iso-8601=seconds)"
echo "Host: $(hostname)"
echo

# Find clean global IPv6 addresses.
mapfile -t IPV6_ADDRESSES < <(
    ip -6 -o address show scope global \
        | awk '{print $4}' \
        | cut -d/ -f1 \
        | sort -u
)

echo "Global IPv6 addresses:"

if ((${#IPV6_ADDRESSES[@]})); then
    printf '  %s\n' "${IPV6_ADDRESSES[@]}"
else
    echo "  None found."
fi

echo

# Back up the UFW settings before changing anything.
if ! cp -a -- "$UFW_CONFIG" "$UFW_BACKUP"; then
    echo "Could not back up $UFW_CONFIG."
    echo "No firewall configuration changes were made."
    exit 1
fi

echo "UFW configuration backup:"
echo "  $UFW_BACKUP"

# Create the modified configuration in a temporary file.
TEMP_CONFIG=$(mktemp "${UFW_CONFIG}.tmp.XXXXXX")

cleanup() {
    rm -f -- "${TEMP_CONFIG:-}"
}
trap cleanup EXIT

cp --preserve=mode,ownership,timestamps \
    "$UFW_CONFIG" "$TEMP_CONFIG"

# Enable IPv6 filtering in the temporary copy.
if grep -qE '^[[:space:]]*IPV6[[:space:]]*=' "$TEMP_CONFIG"; then
    sed -i -E \
        's/^[[:space:]]*IPV6[[:space:]]*=.*$/IPV6=yes/' \
        "$TEMP_CONFIG"
else
    printf '\nIPV6=yes\n' >> "$TEMP_CONFIG"
fi

# Confirm the new setting before replacing the original file.
if ! grep -qE '^IPV6=yes$' "$TEMP_CONFIG"; then
    echo "Could not prepare the new UFW configuration."
    echo "The original configuration was not changed."
    exit 1
fi

# Atomically install the edited configuration.
cat "$TEMP_CONFIG" > "$UFW_CONFIG"
chmod --reference="$UFW_BACKUP" "$UFW_CONFIG"
chown --reference="$UFW_BACKUP" "$UFW_CONFIG"

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
echo "Global IPv6 addresses:"
if ((${#IPV6_ADDRESSES[@]})); then
    printf '  %s\n' "${IPV6_ADDRESSES[@]}"
else
    echo "  None found."
fi

echo
echo "Report saved to:"
echo "  $REPORT"

echo
echo "Read recent UFW logs with:"
echo "  sudo journalctl -k | grep UFW"


#########################
# Run with:

# chmod 700 ufw_ipv6.sh
# sudo bash ufw_ipv6.sh
# Check status: sudo ufw status verbose
