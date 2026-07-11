#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

UFW_CONFIG="/etc/default/ufw"

if (( EUID != 0 )); then
    echo "Run with:"
    echo "  sudo bash ufw-desktop.sh"
    exit 1
fi

command -v ufw >/dev/null 2>&1 || {
    echo "UFW is not installed."
    echo "Install it with:"
    echo "  sudo apt update && sudo apt install ufw"
    exit 1
}

command -v ip >/dev/null 2>&1 || {
    echo "The ip command is missing."
    echo "Install it with:"
    echo "  sudo apt update && sudo apt install iproute2"
    exit 1
}

[[ -f "$UFW_CONFIG" ]] || {
    echo "UFW configuration not found: $UFW_CONFIG"
    exit 1
}

[[ ! -L "$UFW_CONFIG" ]] || {
    echo "Refusing to modify symbolic link: $UFW_CONFIG"
    exit 1
}

echo "Checking UFW IPv6 support..."

if grep -qE \
    '^[[:space:]]*IPV6[[:space:]]*=[[:space:]]*yes[[:space:]]*$' \
    "$UFW_CONFIG"
then
    echo "IPv6 filtering is already enabled."
else
    TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
    BACKUP="${UFW_CONFIG}.backup-${TIMESTAMP}"
    TEMP_FILE="$(mktemp "${UFW_CONFIG}.tmp.XXXXXX")"

    cleanup() {
        rm -f -- "${TEMP_FILE:-}"
    }
    trap cleanup EXIT

    echo "Creating backup:"
    echo "  $BACKUP"

    cp -a -- "$UFW_CONFIG" "$BACKUP"

    if grep -qE '^[[:space:]]*IPV6[[:space:]]*=' "$UFW_CONFIG"; then
        # Replace all active IPV6 settings with one IPV6=yes line.
        awk '
            BEGIN {
                written = 0
            }

            /^[[:space:]]*IPV6[[:space:]]*=/ {
                if (!written) {
                    print "IPV6=yes"
                    written = 1
                }
                next
            }

            {
                print
            }
        ' "$UFW_CONFIG" > "$TEMP_FILE"
    else
        # Preserve the complete original file and append the setting once.
        cat -- "$UFW_CONFIG" > "$TEMP_FILE"
        printf '\nIPV6=yes\n' >> "$TEMP_FILE"
    fi

    # Verify that the resulting file contains exactly one active IPV6 setting.
    IPV6_COUNT="$(
        grep -Ec \
            '^[[:space:]]*IPV6[[:space:]]*=[[:space:]]*yes[[:space:]]*$' \
            "$TEMP_FILE" ||
            true
    )"

    if [[ "$IPV6_COUNT" -ne 1 ]]; then
        echo "IPv6 configuration validation failed."
        exit 1
    fi

    chmod --reference="$UFW_CONFIG" "$TEMP_FILE"
    chown --reference="$UFW_CONFIG" "$TEMP_FILE"

    mv -- "$TEMP_FILE" "$UFW_CONFIG"
    trap - EXIT

    echo "IPv6 filtering has been enabled."
fi

echo
echo "Applying secure desktop defaults..."

ufw default deny incoming
ufw default allow outgoing
ufw default deny routed
ufw logging low
ufw --force enable

echo
echo "Global IPv6 addresses:"

mapfile -t IPV6_ADDRESSES < <(
    ip -6 -o address show scope global |
        awk '{split($4, address, "/"); print address[1]}' |
        sort -u
)

if ((${#IPV6_ADDRESSES[@]})); then
    printf '  %s\n' "${IPV6_ADDRESSES[@]}"
else
    echo "  No global IPv6 address is currently assigned."
fi

echo
echo "UFW status:"
ufw status verbose



