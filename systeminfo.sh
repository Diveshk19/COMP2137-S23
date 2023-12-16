#!/bin/bash


# Source the function library file 
source reportfunctions.sh

# Function to display help
function display_help() {
    echo "Usage: $0 [-h] [-v] [-system] [-disk] [-network]"
    echo "Options:"
    echo "  -h          Display help"
    echo "  -v          Run script verbosely (show errors to the user)"
    echo "  -system     Run computerreport, osreport, cpureport, ramreport, and videoreport"
    echo "  -disk       Run diskreport"
    echo "  -network    Run networkreport"
    exit 0
}

# Function to check for root permissions
function check_root() {
    if [ "$EUID" -ne 0 ]; then
        errormessage "This script requires root privileges. Please run as root."
        exit 1
    fi
}

# Function to run the default full system report
function run_full_report() {
    computerreport
    osreport
    cpureport
    ramreport
    videoreport
    diskreport
    networkreport
}

# Parse command line options
while getopts ":hvsdn" option; do
    case "$option" in
        h) display_help ;;
        v) VERBOSE=true ;;
        s) RUN_SYSTEM=true ;;
        d) RUN_DISK=true ;;
        n) RUN_NETWORK=true ;;
        \?) errormessage "Invalid option: -$OPTARG"
            display_help ;;
    esac
done

# Check for root permissions
check_root

# Run the specified reports based on command line options
if [ "$RUN_SYSTEM" = true ]; then
    computerreport
    osreport
    cpureport
    ramreport
    videoreport
elif [ "$RUN_DISK" = true ]; then
    diskreport
elif [ "$RUN_NETWORK" = true ]; then
    networkreport
else
    run_full_report
fi
