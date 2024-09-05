#!/usr/bin/env bash

# Function to display help menu
function show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --numa              Check NUMA settings"
    echo "  --disable-smt       Temporarily disable SMT"
    echo "  --set-performance   Set CPU governor to performance"
    echo "  --disable-turbo     Disable Turbo Boost (Intel), Turbo Core (AMD), or ARM equivalent"
    echo "  --clear-cache       Clear memory caches"
    echo "  --sync-disks        Sync disks to flush pending writes"
    echo "  --set-thp           Set Transparent HugePages (THP) to madvise"
    echo "  --all               Run all of the above (default)"
    echo "  --help              Show this help message"
}

# Check NUMA settings
function check_numa() {
    echo "=========================================================="
    echo "Checking NUMA settings with numactl"
    if ! numactl --show; then
        echo "ERROR: Failed to run numactl."
        exit 1
    fi
    echo "=========================================================="
}

# Get the current SMT state
function get_smt_state() {
    cat /sys/devices/system/cpu/smt/control
}

# Temporarily disable SMT (Simultaneous Multithreading)
function disable_smt() {
    echo "============================================================="
    echo "Disabling SMT"
    
    if ! echo off | sudo tee /sys/devices/system/cpu/smt/control > /dev/null; then
        echo "ERROR: Failed to disable SMT."
        exit 1
    fi

    echo "SMT state after disabling: $(get_smt_state)"
    echo "============================================================="
}

# Install cpufrequtils if not already installed
function install_cpufrequtils() {
    echo "Installing cpufrequtils"
    if ! sudo apt-get install -y cpufrequtils > /dev/null; then
        echo "ERROR: Failed to install cpufrequtils."
        exit 1
    fi
}

# Set CPU governor to performance
function set_cpu_performance() {
    echo "============================================================="
    echo "Setting CPU governor to performance"

    # Ensure cpufrequtils is installed
    install_cpufrequtils

    if ! echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils > /dev/null; then
        echo "ERROR: Failed to configure CPU governor."
        exit 1
    fi

    # Restart the service to apply the changes
    if ! sudo systemctl restart cpufrequtils; then
        echo "ERROR: Failed to apply CPU governor changes."
        exit 1
    fi

    echo "CPU Governor set to performance"
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    echo "============================================================="
}

# Disable Turbo Boost (Intel), Turbo Core (AMD), or ARM equivalent
function disable_turbo() {
    echo "============================================================="
    echo "Disabling Turbo Boost/Turbo Core/ARM equivalent"

    # Detect CPU and disable the corresponding turbo feature
    if grep -q "Intel" /proc/cpuinfo; then
        if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
            echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
            echo "Intel Turbo Boost disabled."
        else
            echo "ERROR: Unable to disable Intel Turbo Boost. Unsupported system or kernel."
            exit 1
        fi
    elif grep -q "AMD" /proc/cpuinfo; then
        if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
            echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost > /dev/null
            echo "AMD Turbo Core disabled."
        else
            echo "ERROR: Unable to disable AMD Turbo Core. Unsupported system or kernel."
            exit 1
        fi
    elif grep -q "ARM" /proc/cpuinfo; then
        echo "Note: ARM CPUs may not have an equivalent to Turbo Boost, but CPU frequency governors may manage performance."
    else
        echo "ERROR: Unsupported CPU architecture."
        exit 1
    fi

    echo "============================================================="
}

# Sync disks to flush pending writes
function sync_disks() {
    echo "============================================================="
    echo "Syncing disks to flush pending writes"
    if ! sync; then
        echo "ERROR: Disk sync failed."
        exit 1
    fi
    echo "Disk sync completed"
    echo "============================================================="
}

# Clear memory cache
function clear_cache() {
    echo "============================================================="
    echo "Clearing memory caches"
    if ! echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null; then
        echo "ERROR: Failed to clear memory caches."
        exit 1
    fi
    echo "Memory caches cleared"
    echo "============================================================="
}

# Set Transparent HugePages (THP) to madvise
function set_thp_madvise() {
    echo "============================================================="
    echo "Setting Transparent HugePages (THP) to madvise"
    if ! echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null; then
        echo "ERROR: Failed to set THP to madvise."
        exit 1
    fi

    if ! grep -q "\[madvise\]" /sys/kernel/mm/transparent_hugepage/enabled; then
        echo "ERROR: THP madvise setting not confirmed."
        exit 1
    fi
    echo "THP set to madvise"
    echo "============================================================="
}

# Parse and handle command-line options
function parse_arguments() {
    if [[ "$#" -eq 0 ]]; then
        # Default: run all functions if no options provided
        run_all
    else
        while [[ "$#" -gt 0 ]]; do
            case $1 in
                --numa) check_numa ;;
                --disable-smt) disable_smt ;;
                --set-performance) set_cpu_performance ;;
                --disable-turbo) disable_turbo ;;
                --clear-cache) clear_cache ;;
                --sync-disks) sync_disks ;;
                --set-thp) set_thp_madvise ;;
                --all) run_all ;;
                --help) show_help; exit 0 ;;
                *) echo "Unknown option: $1"; show_help; exit 1 ;;
            esac
            shift
        done
    fi
}

# Run all functions
function run_all() {
    check_numa
    disable_smt
    set_cpu_performance
    disable_turbo
    sync_disks
    clear_cache
    set_thp_madvise
}

# Main execution starts here
parse_arguments "$@"
