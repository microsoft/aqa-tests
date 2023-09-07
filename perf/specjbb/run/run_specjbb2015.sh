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
# e.g, JAVA=/usr/lib/jvm/java-17-openjdk-arm64/bin/java
JAVA=

# Set the location of this project
# e.g. export SPECJBB_BASEDIR=/home/username/workspace/microsoft/aqa-tests/perf/specjbb
# RUN_SCRIPTS_DIR & RUN_OPTIONS_DIR should not need altering
export SPECJBB_BASEDIR=
RUN_SCRIPTS_DIR=$SPECJBB_BASEDIR/run
RUN_OPTIONS_DIR=$SPECJBB_BASEDIR/run/options

# Set the location of the extracted SPECjbb folder
# e.g. export SPECJBB_SRC=/home/username/workspace/microsoft/workspace/SPECjbb2015-1.03
# SPECJBB_JAR & SPECJBB_CONFIG should not need altering
export SPECJBB_SRC=
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

# Source the affinity script so we can split up the CPUs correctly when using NUMA
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
# 
# TODO Refactor alongside runSpecJbbComposite() to remove duplication
#
# You can have => 1 number of runs. We recommend 1 run to start with.
# 
# Each run uses a single Controller
# Each Controller can control X Groups
# Each Group contains Y TransactionInjectors and 1 Backend.
#
# We recommend running with 1 Group containing 1 TI and 1 BE to start with.
# 
# On NUMA enabled hosts we attempt to calculate the number of CPUs per group but 
# you will likely want to manually override that number.
#
###################################################################################
function runSpecJbbMulti() {

  for ((runNumber=1; runNumber<=NUM_OF_RUNS; runNumber=runNumber+1)); do

    # Create timestamp for use in logging, this is split over two lines as timestamp itself is a function
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    # Some O/S setup before each run, see "../../../perf/benchmark_setup.sh"
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
    echo "Launching SPECjbb2015 in multi-jvm mode...     "
    echo
    echo "Run $runNumber: $timestamp"
    echo    
    echo "Starting the Controller JVM"
    
    # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
    # shellcheck disable=SC2086
    local controllerCommand="${JAVA} ${JAVA_OPTS_C} ${SPECJBB_OPTS_C} -jar ${SPECJBB_JAR} -m MULTICONTROLLER ${MODE_ARGS_C} 2>controller.log 2>&1 | tee controller.out &"
    echo "$controllerCommand"
    eval "${controllerCommand}"

    # Save the PID of the Controller JVM so we can report on it later
    # Sleep for 3 seconds for the controller to start.
    # TODO This is brittle, let's detect proper controller start-up
    CTRL_PID=$!
    echo "Controller PID: $CTRL_PID"
    sleep 3

    # Index variable used to help calculate the cpuRange if we have multiple groups and NUMA enabled
    local cpuCount=0

    # Get the cpu count, see "../../../perf/benchmark_setup.sh", results lives in TOTAL_CPU_COUNT
    getTotalCPUs
    # Manually override the total CPU count if you do not want to use all detected cores
    #TOTAL_CPU_COUNT=
    TOTAL_CPU_COUNT=112
    
    # Calculate the total number of CPUs available for each group
    # By default we take 1 CPU away for O/S operations and 1 CPU away for the Controller
    # and split up the rest (bash shell script rounds down)
    # Manually override the number of CPUs per group if you want set that manually
    #CPUS_PER_GROUP=$(TOTAL_CPU_COUNT-2)/$GROUP_COUNT

    # By default we take 1 CPU away for O/S operations and 2 CPU away for the Controller
    #CPUS_PER_GROUP=$(TOTAL_CPU_COUNT-3)/$GROUP_COUNT
    
    # Manually override the number of CPUs per group if you want set that manually

    # 2 Groups scenario 54*2=108
    # 52 CPUs for the BE and 2 CPUs for the TI for each group
    CPUS_PER_GROUP=54
    
    # 4 Groups scenario 27*4=108
    # 25 CPUS for each BE and 2 for each TI
    #CPUS_PER_GROUP=27
    
    # 8 Groups scenario 13*8=104 - we should give more to the controller at this point
    # 11 CPUS for each BE and 2 for each TI
    #CPUS_PER_GROUP=13

    # Start the TransactionInjector JVMs and the Backend JVM for each group, the Controller 
    # will eventually connect and the benchmark will start
    for ((groupNumber=1; groupNumber<GROUP_COUNT+1; groupNumber=groupNumber+1)); do

      local groupId="Group$groupNumber"

      echo -e "\nStarting Transaction Injector JVMs for group $groupId:"

      # Calculate CPUs available via NUMA for this run. We use some math to create a CPU range string
      # TOTAL_CPU_COUNT comes from ../../benchmark_setup.sh
      # e.g., For 64 cores per group and 2 groups                 # Group 1                 Group 2
      local cpuInit=$((cpuCount*CPUS_PER_GROUP))                  # e.g., 0 * 64 = 0        1 * 64 = 64
      local cpuMax=$(($(($((cpuCount+1))*CPUS_PER_GROUP))-1))     # e.g., 1 * 64 - 1 = 63   2 * 64 - 1 = 127
      local cpuRange="${cpuInit}-${cpuMax}"                       # e.g., 0-63              64-127
      echo "cpuRange is: $cpuRange"

      for ((injectorNumber=1; injectorNumber<TI_JVM_COUNT+1; injectorNumber=injectorNumber+1)); do

          local transactionInjectorJvmId="txiJVM$injectorNumber"
          local transactionInjectorName="$groupId.TxInjector.$transactionInjectorJvmId"

          echo "Start $transactionInjectorName"
          
          # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
          # shellcheck disable=SC2086
          local transactionInjectorCommand="numactl --physcpubind=$cpuRange --localalloc ${JAVA} ${JAVA_OPTS_TI} ${SPECJBB_OPTS_TI} -jar ${SPECJBB_JAR} -m TXINJECTOR -G=$groupId -J=${transactionInjectorJvmId} ${MODE_ARGS_TI} > ${transactionInjectorName}.log 2>&1 &"
          # NOTE: If you are not running in NUMA mode then remove the prefix of numactl --physcpubind=$cpuRange --localalloc
          #local transactionInjectorCommand="${JAVA} ${JAVA_OPTS_TI} ${SPECJBB_OPTS_TI} -jar ${SPECJBB_JAR} -m TXINJECTOR -G=$groupId -J=${transactionInjectorJvmId} ${MODE_ARGS_TI} > ${transactionInjectorName}.log 2>&1 &"
          echo "$transactionInjectorCommand"
          eval "${transactionInjectorCommand}"
          echo -e "\t${transactionInjectorName} PID = $!"

          # Sleep for 1 second to allow each transaction injector JVM to start.
          # TODO this seems arbitrary, we should detect the actual start of the TI
          sleep 1
      done

      local backendJvmId=beJVM
      local backendName="$groupId.Backend.${backendJvmId}"
      
      # Add GC logging to the backend's JVM options. We use the recommended settings for GCToolkit (https://www.github.com/microsoft/gctoolkit).
      JAVA_OPTS_BE_WITH_GC_LOG="$JAVA_OPTS_BE -Xlog:gc*,gc+ref=debug,gc+phases=debug,gc+age=trace,safepoint:file=${backendName}_gc.log"

      echo "Start $BE_NAME"
      # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
      # shellcheck disable=SC2086
      local backendCommand="numactl --physcpubind=$cpuRange --localalloc ${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m BACKEND -G=$groupId -J=$backendJvmId ${MODE_ARGS_BE} > ${backendName}.log 2>&1 &"
      # NOTE: If you are not running in NUMA mode then remove the numactl --physcpubind=$cpuRange --localalloc prefix
      #local backendCommand="${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m BACKEND -G=$groupId -J=$backendJvmId ${MODE_ARGS_BE} > ${backendName}.log 2>&1 &"
      echo "$backendCommand"
      eval "${backendCommand}"
      echo -e "\t$BE_NAME PID = $!"

      # Sleep for 1 second to allow each backend JVM to start.
      # TODO this seems arbitrary, we should detect the actual start of the BE
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
#
###################################################################################
function runSpecJbbComposite() {

  for ((runNumber=1; runNumber<=NUM_OF_RUNS; runNumber=runNumber+1)); do

    # Create timestamp for use in logging, this is split over two lines as timestamp itself is a function
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    # Some O/S setup before each run
    beforeEachRun

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
    local backendCommand="numactl --physcpubind=$cpuRange --localalloc ${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_C} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m COMPOSITE ${MODE_ARGS_BE} 2>&1 | tee composite.out &"
    # NOTE: If you are not running in NUMA mode then remove the numactl --physcpubind=$cpuRange --localalloc prefix
    #local backendCommand="${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_C} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m COMPOSITE ${MODE_ARGS_BE} 2>&1 | tee composite.out &"
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

# NOTE: If the system does not have NUMA, then comment this out if you wish
checkNumaReadiness

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
#elif [ "$MODE" == "distributed" ]; then
#    echo "Running in Distributed mode"
#    showConfig
#    runSpecJbbDistributed
fi

# exit gracefully once we are done
exit 0
