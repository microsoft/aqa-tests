#!/usr/bin/env bash

###################################################################################
#
# run_specjbb2015.sh - 13th Of July 2023
# 
# NOTE for Microsoft Developers. This script was hastily extracted from the 
# aqa-test perf lab framework to be used standalone. Some of the logical flow may 
# come across as a little inverted due to this extraction process.
#
# Usage:
#
# 1. Set the environment variables at the top of this script
# 2. Set the environment variables in the options/specjbb-composite-config.sh or 
#    options/specjbb-multijvm-config.sh script depending on the mode you want to 
#    run in
# 3. ./run_specjbb2015.sh - this will run the benchmark and generate a report 
# 
###################################################################################

###################################################################################
# Environment Variables
###################################################################################

# Set your Java executable here
# e.g, JAVA=/Library/Java/JavaVirtualMachines/microsoft-11.jdk/Contents/Home/bin/java
JAVA=/Library/Java/JavaVirtualMachines/microsoft-11.jdk/Contents/Home/bin/java

# Set the location of this project
# e.g. export SPECJBB_BASEDIR=/Users/martijnverburg/Documents/workspace/microsoft/aqa-tests/perf/specjbb
export SPECJBB_BASEDIR=/Users/martijnverburg/Documents/workspace/microsoft/aqa-tests/perf/specjbb
# RUN_SCRIPTS_DIR & RUN_OPTIONS_DIR should not need altering
RUN_SCRIPTS_DIR=$SPECJBB_BASEDIR/run
RUN_OPTIONS_DIR=$SPECJBB_BASEDIR/run/options

# Set the location of the extracted SPECjbb folder
# e.g. export SPECJBB_SRC=/Users/martijnverburg/Documents/workspace/SPECjbb2015-1.03
export SPECJBB_SRC=/Users/martijnverburg/Documents/workspace/SPECjbb2015-1.03
# SPECJBB_JAR & SPECJBB_CONFIG should not need altering
SPECJBB_JAR=$SPECJBB_SRC/specjbb2015.jar
SPECJBB_CONFIG=$SPECJBB_SRC/config

# The reports dir will get created by this script so don't create it up front
RESULTS_DIR=$SPECJBB_BASEDIR/reports

# Set the mode you want to run in: composite, multi-jvm or distributed (not supported yet)
#export MODE="composite"
export MODE="multi-jvm"
#export MODE="distributed"

###################################################################################
# Source common scripts
###################################################################################

# source the affinity script so we can split up the CPUs correctly when using NUMA
. "../../../perf/affinity.sh"

# Source in utility functions you can use for any benchmark (clean caches etc)
. "../../../perf/benchmark_setup.sh"

###################################################################################
# Functions
###################################################################################

###################################################################################
# showConfig() - echo out what our config is set to
###################################################################################
function showConfig() {
  echo "=========================================================="
  echo "SPECjbb2015 Configuration"
  echo "SPECJBB_BASEDIR: ${SPECJBB_BASEDIR}"
  echo "JAVA: ${JAVA}"
  echo "SPECJBB_JAR: ${SPECJBB_JAR}"
  echo "SPECJBB_CONFIG: ${SPECJBB_CONFIG}"
  echo "RUN_SCRIPTS_DIR: ${RUN_SCRIPTS_DIR}"
  echo "RUN_OPTIONS_DIR: ${RUN_OPTIONS_DIR}"
  echo "RESULTS_DIR: ${RESULTS_DIR}"
  echo "Mode: ${MODE}"
  echo ""
  echo "Number of Runs: ${NUM_OF_RUNS}"
  echo "Number of Groups: ${GROUP_COUNT}"
  echo "Number of Transaction Injectors: ${TI_JVM_COUNT}"
  echo "Controller Options: ${JAVA_OPTS_C}"
  echo "Transaction Injector Options: ${JAVA_OPTS_TI}"
  echo "Backend Options: ${JAVA_OPTS_BE}"
  echo "Results Directory: ${RESULTS_DIR}"
  echo "=========================================================="
}

###################################################################################
# runSpecJbbMulti() The main run script for SPECjbb2015 in MultiJVM mode
# TODO Refactor alongside runSpecJbbMultiJVM() to remove duplication
###################################################################################
function runSpecJbbMulti() {

  for ((runNumber=1; runNumber<=NUM_OF_RUNS; runNumber=runNumber+1)); do

    # Create timestamp for use in logging, this is split over two lines as timestamp itself is a function
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    # Some O/S setup before each run, see "../../../perf/benchmark_setup.sh"
    # TODO reenable
    #beforeEachRun

    # Create temp result directory                
    local result
    result="${RESULTS_DIR%\"}"
    result="${result#\"}"
    mkdir -pv "${result}"
    
    # Copy current SPECjbb2015 config for this run to the result directory
    cp -r "${SPECJBB_CONFIG}" "${result}"
    cd "${result}" || exit
    
    # Start logging
    echo "==============================================="
    echo "Launching SPECjbb2015 in ${MODE} mode...       "
    echo
    echo "Run $runNumber: $timestamp"
    echo

    echo "Starting the Controller JVM"
    # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
    # shellcheck disable=SC2086
    # TODO check with Monica, won't the controller interfere with the cpu Range of 0-63 that we have reserved for the TI and BE here?
    local controllerCommand="${JAVA} ${JAVA_OPTS_C} ${SPECJBB_OPTS_C} -jar ${SPECJBB_JAR} -m MULTICONTROLLER ${MODE_ARGS_C} 2>controller.log 2>&1 | tee controller.out &"
    echo "$controllerCommand"
    eval "${controllerCommand}"

    # Save the PID of the Controller JVM
    CTRL_PID=$!
    echo "Controller PID: $CTRL_PID"

    # TODO This is brittle, let's detect proper controller start-up
    # Sleep for 3 seconds for the controller to start.
    sleep 3

    local cpuCount=0

    # Get the cpu count, see "../../../perf/benchmark_setup.sh"
    getTotalCPUs

    # Start the TransactionInjector and Backend JVMs for each group
    for ((groupNumber=1; groupNumber<GROUP_COUNT+1; groupNumber=groupNumber+1)); do

      local groupId="Group$groupNumber"

      echo -e "\nStarting Transaction Injector JVMs for group $groupId:"

      # Calculate CPUs available via NUMA for this run. We use some math to create a CPU range string
      # E.g if totalCpuCount is 64, then we should use 0-63
      local cpuInit=$((cpuCount*TOTAL_CPU_COUNT))                 # e.g., 0 * 64 = 0
      local cpuMax=$(($(($((cpuCount+1))*TOTAL_CPU_COUNT))-1))    # e.g., 1 * 64 - 1 = 63
      local cpuRange="${cpuInit}-${cpuMax}"                       # e.g., 0-63
      echo "cpuRange is: $cpuRange"

      for ((injectorNumber=1; injectorNumber<TI_JVM_COUNT+1; injectorNumber=injectorNumber+1)); do

          local transactionInjectorJvmId="txiJVM$injectorNumber"
          local transactionInjectorName="$groupId.TxInjector.$transactionInjectorJvmId"

          echo "Start $transactionInjectorName"
          
          # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
          # shellcheck disable=SC2086
          # TODO reenable
          #local transactionInjectorCommand="numactl --physcpubind=$cpuRange --localalloc ${JAVA} ${JAVA_OPTS_TI} ${SPECJBB_OPTS_TI} -jar ${SPECJBB_JAR} -m TXINJECTOR -G=$groupId -J=${transactionInjectorJvmId} ${MODE_ARGS_TI} > ${transactionInjectorName}.log 2>&1 &"
          local transactionInjectorCommand="${JAVA} ${JAVA_OPTS_TI} ${SPECJBB_OPTS_TI} -jar ${SPECJBB_JAR} -m TXINJECTOR -G=$groupId -J=${transactionInjectorJvmId} ${MODE_ARGS_TI} > ${transactionInjectorName}.log 2>&1 &"
          echo "$transactionInjectorCommand"
          eval "${transactionInjectorCommand}"
          echo -e "\t${transactionInjectorName} PID = $!"

          # TODO this seems arbitrary, we should detect the actual start of the TI
          # Sleep for 1 second to allow each transaction injector JVM to start.
          sleep 1
      done

      local backendJvmId=beJVM
      local backendName="$groupId.Backend.${backendJvmId}"
      
      # Add GC logging to the backend's JVM options. We use the recommended settings for GCToolkit (https://www.github.com/microsoft/gctoolkit).
      JAVA_OPTS_BE_WITH_GC_LOG="$JAVA_OPTS_BE -Xlog:gc*,gc+ref=debug,gc+phases=debug,gc+age=trace,safepoint:file=${backendName}_gc.log"

      echo "Start $BE_NAME"
      # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
      # shellcheck disable=SC2086
      # TODO reenable
      #local backendCommand="numactl --physcpubind=$cpuRange --localalloc ${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m BACKEND -G=$groupId -J=$backendJvmId ${MODE_ARGS_BE} > ${backendName}.log 2>&1 &"
      local backendCommand="${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m BACKEND -G=$groupId -J=$backendJvmId ${MODE_ARGS_BE} > ${backendName}.log 2>&1 &"
      echo "$backendCommand"
      eval "${backendCommand}"
      echo -e "\t$BE_NAME PID = $!"

      # TODO this seems arbitrary, we should detect the actual start of the BE
      # Sleep for 1 second to allow each backend JVM to start.
      sleep 1

      # Increment the CPU count so that we use a new range for the next run
      cpucount=$((cpucount+1))
    done

    echo
    echo "SPECjbb2015 is running..."
    echo "Please monitor $result/controller.out for progress"

    wait $CTRL_PID
    echo
    echo "Controller has stopped"

    echo "SPECjbb2015 has finished"
    echo
    
    cd "${WORKING_DIR}" || exit

  done
}

###################################################################################
# runSpecJbbComposite() The main run script for SPECjbb2015 in MultiJVM mode
#
# TODO Refactor alongside runSpecJbbMultiJVM() to remove duplication
###################################################################################
function runSpecJbbComposite() {

  for ((runNumber=1; runNumber<=NUM_OF_RUNS; runNumber=runNumber+1)); do

    # Create timestamp for use in logging, this is split over two lines as timestamp itself is a function
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    # Some O/S setup before each run
    # TODO reenable
    #beforeEachRun

    # Create temp result directory                
    local result
    result="${RESULTS_DIR%\"}"
    result="${result#\"}"
    mkdir -pv "${result}"
    
    # Copy current SPECjbb2015 config for this run to the result directory
    cp -r "${SPECJBB_CONFIG}" "${result}"
    cd "${result}" || exit
    
    # Start logging
    echo "==============================================="
    echo "Launching SPECjbb2015 in Composite mode...     "
    echo
    echo "Run $runNumber: $timestamp"
    echo

    local cpuCount=0

    getTotalCPUs

    # Calculate CPUs available via NUMA for this run. We use some math to create a CPU range string
    # E.g if totalCpuCount is 64, then we should use 0-63
    local cpuInit=$((cpuCount*TOTAL_CPU_COUNT))                 # e.g., 0 * 64 = 0
    local cpuMax=$(($(($((cpuCount+1))*TOTAL_CPU_COUNT))-1))    # e.g., 1 * 64 - 1 = 63
    local cpuRange="${cpuInit}-${cpuMax}"                       # e.g., 0-63
    echo "cpuRange is: $cpuRange"

    local backendJvmId=beJVM
    local backendName="$groupId.Backend.${backendJvmId}"
    
    # Add GC logging to the backend's JVM options. We use the recommended settings for GCToolkit (https://www.github.com/microsoft/gctoolkit).
    JAVA_OPTS_BE_WITH_GC_LOG="$JAVA_OPTS_BE -Xlog:gc*,gc+ref=debug,gc+phases=debug,gc+age=trace,safepoint:file=${backendName}_gc.log"

    echo "Start $BE_NAME"
    # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
    # shellcheck disable=SC2086
    # TODO reenable
    #local backendCommand="numactl --physcpubind=$cpuRange --localalloc ${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_C} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m COMPOSITE ${MODE_ARGS_BE} 2>&1 | tee composite.out &"
    local backendCommand="${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_C} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m COMPOSITE ${MODE_ARGS_BE} 2>&1 | tee composite.out &"
    echo "$backendCommand"
    eval "${backendCommand}"
    local compositePid=$!
    echo "Composite JVM PID = $compositePid"
    sleep 3

    # Increment the CPU count so that we use a new range for the next run
    cpucount=$((cpucount+1))
    
    echo
    echo "SPECjbb2015 is running..."
    echo "Please monitor $result/composite.out for progress"
    wait $compositePid

    echo "SPECjbb2015 has finished"
    echo
    
    cd "${WORKING_DIR}" || exit

  done
}

# TODO reenable 
#checkNumaReadiness

if [ "$MODE" == "multi-jvm" ]; then
    echo "Running in MultiJVM mode"
    . "./options/specjbb-multijvm-config.sh"
    showConfig
    runSpecJbbMulti
elif [ "$MODE" == "composite" ]; then
    echo "Running in Composite mode"
    . "./options/specjbb-composite-config.sh"
    showConfig
    runSpecJbbComposite
elif [ "$MODE" == "distributed" ]; then
    echo "Running in Distributed mode"
    showConfig
    runSpecJbbDistributed
fi

# exit gracefully once we are done
exit 0
