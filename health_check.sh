#!/usr/bin/bash

# ==============================================================================
# Script: Menu-Based System Health Monitoring & Reporting
# Author: Faizan
# ==============================================================================

RECIPIENT="admin@example.com"  # Replace with your email address
LOG_FILE="/tmp/system_health_report.txt"

# Thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90
SERVICES=("ssh" "cron")

# Function: Header
print_header() {
    echo "=================================================="
    echo "         SYSTEM HEALTH MONITORING SYSTEM          "
    echo "=================================================="
}

# Function: CPU Check
check_cpu() {
    echo -e "\n--- [1] CPU USAGE ---"
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print $1}')
    CPU_USAGE=$(awk "BEGIN {print 100 - $CPU_IDLE}")
    echo "Current CPU Usage: ${CPU_USAGE}%"
    
    CPU_INT=$(printf "%.0f" "$CPU_USAGE")
    if [ "$CPU_INT" -gt "$CPU_THRESHOLD" ]; then
        echo "WARNING: High CPU usage detected!"
    else
        echo "Status: OK"
    fi
}

# Function: Memory Check
check_memory() {
    echo -e "\n--- [2] MEMORY USAGE ---"
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
    MEM_USAGE=$(( MEM_USED * 100 / MEM_TOTAL ))
    
    echo "Total RAM: ${MEM_TOTAL} MB | Used: ${MEM_USED} MB (${MEM_USAGE}%)"
    if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
        echo "WARNING: High Memory usage detected!"
    else
        echo "Status: OK"
    fi
}

# Function: Disk Space Check
check_disk() {
    echo -e "\n--- [3] DISK USAGE ---"
    df -h | grep -E '^/dev/' | awk '{ print $5 " " $1 " (" $6 ")" }' | while read -r output; do
        USAGE=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1)
        PARTITION=$(echo "$output" | awk '{ print $2 " " $3}')
        echo "Partition $PARTITION: ${USAGE}% used"
        if [ "$USAGE" -ge "$DISK_THRESHOLD" ]; then
            echo "WARNING: Low disk space on $PARTITION!"
        fi
    done
}

# Function: Services Check
check_services() {
    echo -e "\n--- [4] CRITICAL SERVICES STATUS ---"
    for SERVICE in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$SERVICE"; then
            echo "Service '$SERVICE': RUNNING"
        else
            echo "Service '$SERVICE': DOWN"
        fi
    done
}

# Function: Generate & Send Email Report
send_report() {
    echo -e "\nGenerating full report..."
    {
        print_header
        echo "Host: $(hostname)"
        echo "Date: $(date)"
        echo "Uptime: $(uptime -p)"
        check_cpu
        check_memory
        check_disk
        check_services
    } > "$LOG_FILE"

    echo "Report generated at $LOG_FILE"
    
    if command -v mailx &> /dev/null; then
        mailx -s "System Health Report - $(hostname)" "$RECIPIENT" < "$LOG_FILE"
        echo "Email sent to $RECIPIENT"
    elif command -v mail &> /dev/null; then
        mail -s "System Health Report - $(hostname)" "$RECIPIENT" < "$LOG_FILE"
        echo "Email sent to $RECIPIENT"
    else
        echo "Note: 'mailx' or 'mail' command not found. Install mailutils to send emails."
    fi
}

# Main Interactive Menu Loop
while true; do
    clear
    print_header
    echo "1. Check CPU Usage"
    echo "2. Check Memory Usage"
    echo "3. Check Disk Space"
    echo "4. Check Critical Services"
    echo "5. Generate & Email Full Health Report"
    echo "6. Exit"
    echo "=================================================="
    read -p "Enter your choice [1-6]: " choice

    case $choice in
        1) check_cpu ;;
        2) check_memory ;;
        3) check_disk ;;
        4) check_services ;;
        5) send_report ;;
        6) echo -e "\nExiting... Goodbye!"; exit 0 ;;
        *) echo -e "\nInvalid option! Please select 1-6." ;;
    esac

    echo ""
    read -p "Press [Enter] key to return to menu..."
done
