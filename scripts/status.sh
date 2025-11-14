#!/bin/bash

# System Status Script
# Shows critical system information on login

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠  $1${NC}"
}

# Function to print errors
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Get hostname and uptime
HOSTNAME=$(hostname)
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)

# Print header
echo ""
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_header "  System Status: $HOSTNAME"
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# System info
echo -e "${BOLD}Uptime:${NC} $UPTIME"
echo -e "${BOLD}Load:${NC} $LOAD"
echo ""

# CPU and Memory
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEM_INFO=$(free -h | awk '/^Mem:/ {printf "%s / %s (%.0f%%)", $3, $2, ($3/$2)*100}')
echo -e "${BOLD}CPU Usage:${NC} ${CPU_USAGE}%"
echo -e "${BOLD}Memory:${NC} $MEM_INFO"
echo ""

# Disk usage check
print_header "Disk Usage:"
DISK_WARNING=false
while IFS= read -r line; do
    USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    MOUNT=$(echo "$line" | awk '{print $6}')

    if [ "$USAGE" -ge 90 ]; then
        print_error "$line"
        DISK_WARNING=true
    elif [ "$USAGE" -ge 80 ]; then
        print_warning "$line"
        DISK_WARNING=true
    fi
done < <(df -h --output=source,size,used,avail,pcent,target | grep -E '^/dev/' | grep -v '/boot')

if [ "$DISK_WARNING" = false ]; then
    print_success "All disks below 80% usage"
fi
echo ""

# Failed systemd services
FAILED_SERVICES=$(systemctl --failed --no-pager --no-legend | wc -l)
if [ "$FAILED_SERVICES" -gt 0 ]; then
    print_header "Failed Services:"
    print_error "$FAILED_SERVICES failed service(s) detected"
    systemctl --failed --no-pager --no-legend | while read -r line; do
        echo "  $line"
    done
    echo ""
fi

# Docker status (if installed and running)
if command -v docker &> /dev/null; then
    if systemctl is-active --quiet docker 2>/dev/null; then
        TOTAL_CONTAINERS=$(docker ps -a --format '{{.Names}}' 2>/dev/null | wc -l)
        RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
        STOPPED_CONTAINERS=$((TOTAL_CONTAINERS - RUNNING_CONTAINERS))

        if [ "$TOTAL_CONTAINERS" -gt 0 ]; then
            print_header "Docker Containers:"
            if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
                echo -e "${GREEN}  Running: $RUNNING_CONTAINERS${NC}"
                docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null | tail -n +2 | while read -r line; do
                    echo "    ✓ $line"
                done
            fi

            if [ "$STOPPED_CONTAINERS" -gt 0 ]; then
                echo -e "${YELLOW}  Stopped: $STOPPED_CONTAINERS${NC}"
            fi
            echo ""
        fi
    fi
fi

print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
