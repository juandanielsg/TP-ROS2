#!/bin/bash
# Usage: ./find-tbot.sh tbot<N>   (N = 1..5)
# Scans the subnet and finds the current IPs of a robot's Raspberry Pi and Create3
# by matching their known MAC addresses in the ARP cache.

SUBNET="192.168.13"

declare -A RASP_MAC=(
    [tbot1]="d8:3a:dd:36:ad:ad"
    [tbot2]="d8:3a:dd:b8:71:d1"
    [tbot3]="d8:3a:dd:34:f1:8c"
    [tbot4]="d8:3a:dd:36:ae:7e"
    [tbot5]="d8:3a:dd:40:ac:69"
)

declare -A CREATE_MAC=(
    [tbot1]="4c:b9:ea:2e:8b:a3"
    [tbot2]="50:14:79:44:68:ef"
    [tbot3]="4c:b9:ea:2e:8b:e6"
    [tbot4]="4c:b9:ea:2e:96:7d"
    [tbot5]="4c:b9:ea:2e:94:fc"
)

TARGET=$1

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 tbot<N>   (N = 1..5)"
    exit 1
fi

if [[ -z "${RASP_MAC[$TARGET]}" ]]; then
    echo "Unknown robot: '$TARGET'. Valid options: ${!RASP_MAC[*]}"
    exit 1
fi

echo "Scanning $SUBNET.0/24 — this takes a few seconds..."
for i in $(seq 1 254); do
    ping -c1 -W1 "$SUBNET.$i" &>/dev/null &
done
wait

# Look up the current IP for a given MAC using /proc/net/arp (no dependencies)
# /proc/net/arp columns: IP HWtype Flags MAC Mask Device
find_ip_by_mac() {
    local target_mac
    target_mac=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr '-' ':')
    awk -v mac="$target_mac" 'NR>1 && tolower($4)==mac {print $1}' /proc/net/arp
}

RASP_IP=$(find_ip_by_mac "${RASP_MAC[$TARGET]}")
CREATE_IP=$(find_ip_by_mac "${CREATE_MAC[$TARGET]}")

echo ""
echo "Results for $TARGET:"
printf "  Raspberry Pi  (MAC %s): %s\n" "${RASP_MAC[$TARGET]}" "${RASP_IP:-NOT FOUND}"
printf "  Create3 base  (MAC %s): %s\n" "${CREATE_MAC[$TARGET]}" "${CREATE_IP:-NOT FOUND}"
