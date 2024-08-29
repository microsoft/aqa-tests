#!/usr/bin/env bash

# Function to determine what is set in terms of NUMA and possibly others et al
function checkHostReadiness() {
  echo "=========================================================="
  echo "Running numactl --show to determine if/how NUMA is enabled"
  echo 
  numactl --show
  echo "=========================================================="
}

# Function to check and echo the current SMT state
function checkSMTState() {
    local smt_state
    smt_state=$(cat /sys/devices/system/cpu/smt/control)
    echo "Current SMT State: $smt_state"
}

# Function to temporarily disable SMT
function disableSMT() {
    echo "============================================================="
    echo "Temporarily Disabling SMT (Simultaneous Multithreading)"
    
    # Echo the SMT state before disabling
    echo "SMT state before change:"
    checkSMTState

    # Temporarily disable SMT (this does not persist after reboot)
    echo off | sudo tee /sys/devices/system/cpu/smt/control > /dev/null
    
    # Echo the SMT state after disabling
    echo "SMT state after temporary change:"
    checkSMTState

    echo "SMT has been temporarily disabled. This change will not persist after a reboot."
    echo "============================================================="
}

# Function to install cpufrequtils and set CPU governor to performance
function setCPUGovernorToPerformance() {
    echo "============================================================="
    echo "Installing cpufrequtils and setting CPU governor to performance"

    # Install cpufrequtils
    sudo apt-get install -y cpufrequtils
    
    # Echo the current CPU governor state before change
    echo "Current CPU Governor State:"
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

    # Set the governor to "performance"
    echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils > /dev/null

    # Apply the performance governor setting
    sudo systemctl restart cpufrequtils

    # Echo the CPU governor state after change
    echo "CPU Governor State after setting to performance:"
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

    echo "NOTE: Unclear how this interacts with the hypervisor."
    echo "NOTE: Unclear if this can be overridden by other hardware mechanisms."
    echo "Intended to ensure maximum CPU performance."
    echo "============================================================="
}

# Get the total CPU count from the affinity.sh script
TOTAL_CPU_COUNT=0
function getTotalCPUs() {
    
    # Extract total CPU count from affinity.sh
    TOTAL_CPU_COUNT=$(get_cpu_count)

    if [ -z "$TOTAL_CPU_COUNT" ]; then
      echo "ERROR: Could not determine total CPU count, exiting"
      exit 1
    fi

    echo "CPU Count: $TOTAL_CPU_COUNT"
    export TOTAL_CPU_COUNT
}

# Make sure the O/S disks and memory et al are cleared before a run
function beforeEachRun() {
    echo "============================================================="
    echo "Starting sync to flush any pending disk writes"
    sync
    if [ $? -ne 0 ]; then
        echo "ERROR: Sync failed, exiting"
        exit 1
    fi
    echo "sync completed"
    echo

    echo "Clearing the memory caches"
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    if [ $? -ne 0 ]; then
        echo "ERROR: Clearing memory caches failed, exiting"
        exit 1
    fi
    echo "Memory caches cleared"
    echo

    echo "Setting madvise for THP"
    echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
    if [ $? -ne 0 ]; then
        echo "ERROR: Setting THP to madvise failed, exiting"
        exit 1
    fi
    echo 
    echo "Checking that madvise was set:"
    grep -q "\[madvise\]" /sys/kernel/mm/transparent_hugepage/enabled
    if [ $? -ne 0 ]; then
        echo "ERROR: THP madvise setting not confirmed, exiting"
        exit 1
    fi
    cat /sys/kernel/mm/transparent_hugepage/enabled
    echo "============================================================="
}

# Main execution starts here
checkHostReadiness
getTotalCPUs
beforeEachRun

# Temporarily disable SMT
disableSMT

# Set CPU governor to performance
setCPUGovernorToPerformance
