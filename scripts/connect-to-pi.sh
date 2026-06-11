#!/bin/bash
# Usage: ./connect-to-pi.sh tbot<N>   (N = 1..5)

declare -A RASP_IPS=(
    [tbot1]=192.168.13.114
    [tbot2]=192.168.13.101
    [tbot3]=192.168.13.109
    [tbot4]=192.168.13.100
    [tbot5]=192.168.13.116
)

TARGET=$1

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 tbot<N>   (N = 1..5)"
    exit 1
fi

IP="${RASP_IPS[$TARGET]}"

if [[ -z "$IP" ]]; then
    echo "Unknown robot: '$TARGET'. Valid options: ${!RASP_IPS[*]}"
    exit 1
fi

echo "Connecting to $TARGET ($IP)..."
ssh ubuntu@"$IP"
