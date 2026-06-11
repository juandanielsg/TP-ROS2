#!/bin/bash
# Usage: ./check_robots.sh [-w <seconds>]
#   -w <seconds>   refresh continuously every N seconds (default: run once)

REFRESH=0

while getopts "w:" opt; do
    case $opt in
        w) REFRESH=$OPTARG ;;
        *) echo "Usage: $0 [-w <seconds>]"; exit 1 ;;
    esac
done

# ── Network map ──────────────────────────────────────────────────────────────

declare -A PC_IPS=(
    [ros-pc1]=192.168.13.103
    [ros-pc2]=192.168.13.105
    [ros-pc3]=192.168.13.107
    [ros-pc4]=192.168.13.108
    [ros-pc5]=192.168.13.111
)

# Raspberry Pi IP for each robot (the only host we connect to)
declare -A ROBOT_RASP=(
    [Turtle1]=192.168.13.114
    [Turtle2]=192.168.13.101
    [Turtle3]=192.168.13.109
    [Turtle4]=192.168.13.100
    [Turtle5]=192.168.13.116
)

# Create3 IP for each robot
declare -A ROBOT_CREATE=(
    [Turtle1]=192.168.13.115
    [Turtle2]=192.168.13.102
    [Turtle3]=192.168.13.110
    [Turtle4]=192.168.13.104
    [Turtle5]=192.168.13.117
)

PC_ORDER=(ros-pc1 ros-pc2 ros-pc3 ros-pc4 ros-pc5)
ROBOT_ORDER=(Turtle1 Turtle2 Turtle3 Turtle4 Turtle5)

# ── Colors ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────────────

ping_host() {
    ping -c 1 -W 1 "$1" > /dev/null 2>&1
}

# Ping a host in the background, write "0" or "1" to a temp file
async_ping() {
    local key=$1 ip=$2 tmpdir=$3
    if ping_host "$ip"; then
        echo 1 > "$tmpdir/$key"
    else
        echo 0 > "$tmpdir/$key"
    fi
}

status_dot() {
    # $1 = result file path, $2 = label, $3 = ip
    local val
    val=$(cat "$1" 2>/dev/null)
    if [[ "$val" == "1" ]]; then
        printf "  ${GREEN}●${NC} %-10s ${DIM}%s${NC}\n" "$2" "$3"
    else
        printf "  ${RED}●${NC} %-10s ${DIM}%s${NC}\n" "$2" "$3"
    fi
}

# ── Main display ─────────────────────────────────────────────────────────────

run_check() {
    local tmpdir
    tmpdir=$(mktemp -d)

    # Launch all pings in parallel
    for name in "${PC_ORDER[@]}"; do
        async_ping "pc_$name" "${PC_IPS[$name]}" "$tmpdir" &
    done
    for name in "${ROBOT_ORDER[@]}"; do
        async_ping "rasp_$name" "${ROBOT_RASP[$name]}" "$tmpdir" &
        async_ping "create_$name" "${ROBOT_CREATE[$name]}" "$tmpdir" &
    done
    wait

    # ── Print results ──────────────────────────────────────────────────────
    clear
    printf "${BOLD}Robot status — %s${NC}\n\n" "$(date '+%H:%M:%S')"

    printf "${BOLD}  %-12s %-18s %-18s${NC}\n" "Robot" "Raspberry Pi" "Create3"
    printf "  %s\n" "────────────────────────────────────────────────"

    for i in "${!ROBOT_ORDER[@]}"; do
        name="${ROBOT_ORDER[$i]}"
        pc="${PC_ORDER[$i]}"

        rasp_val=$(cat "$tmpdir/rasp_$name" 2>/dev/null)
        create_val=$(cat "$tmpdir/create_$name" 2>/dev/null)
        pc_val=$(cat "$tmpdir/pc_$pc" 2>/dev/null)

        # Raspberry dot
        if [[ "$rasp_val" == "1" ]]; then
            rasp_str="${GREEN}● ${ROBOT_RASP[$name]}${NC}"
        else
            rasp_str="${RED}✗ ${ROBOT_RASP[$name]}${NC}"
        fi

        # Create3 dot
        if [[ "$create_val" == "1" ]]; then
            create_str="${GREEN}● ${ROBOT_CREATE[$name]}${NC}"
        else
            create_str="${RED}✗ ${ROBOT_CREATE[$name]}${NC}"
        fi

        # PC dot
        if [[ "$pc_val" == "1" ]]; then
            pc_str="${GREEN}●${NC}"
        else
            pc_str="${RED}✗${NC}"
        fi

        printf "  ${BOLD}%-10s${NC}  %-30b  %-30b  PC: %s %s\n" \
            "$name" "$rasp_str" "$create_str" "$pc_str" "${DIM}($pc)${NC}"
    done

    printf "\n${DIM}Legend:  ${GREEN}●${NC}${DIM} online   ${RED}✗${NC}${DIM} offline${NC}\n"
    [[ "$REFRESH" -gt 0 ]] && printf "${DIM}Refreshing every ${REFRESH}s — Ctrl+C to stop${NC}\n"

    rm -rf "$tmpdir"
}

# ── Loop ─────────────────────────────────────────────────────────────────────

run_check
while [[ "$REFRESH" -gt 0 ]]; do
    sleep "$REFRESH"
    run_check
done
