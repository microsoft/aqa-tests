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
# e.g., JAVA=/usr/lib/jvm/java-17-openjdk-arm64/bin/java
#JAVA=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home/bin/java
JAVA=

# Set the location of this project
# e.g., export SPECJBB_BASEDIR=/home/username/workspace/microsoft/aqa-tests/perf/specjbb
#export SPECJBB_BASEDIR=/Users/martijnverburg/Documents/workspace/microsoft/aqa-tests/perf/specjbb
# RUN_SCRIPTS_DIR & RUN_OPTIONS_DIR should not need altering
export SPECJBB_BASEDIR=
RUN_SCRIPTS_DIR=$SPECJBB_BASEDIR/run
RUN_OPTIONS_DIR=$SPECJBB_BASEDIR/run/options

# Set the location of the extracted SPECjbb folder
# e.g., export SPECJBB_SRC=/home/username/workspace/microsoft/workspace/SPECjbb2015-1.03
#export SPECJBB_SRC=/Users/martijnverburg/Documents/workspace/SPECjbb2015-1.03
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
  echo "Number of Nodes: ${NODE_COUNT}"
  echo "Total Number of Groups: ${GROUP_COUNT}"
  echo "Number of Groups Per Node: ${GROUPS_PER_NODE_COUNT}"
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

    #########################################################

    # Get the cpu count, see "../../../perf/benchmark_setup.sh", results lives in TOTAL_CPU_COUNT
    getTotalCPUs
    # Manually override the total CPU count if you do not want to use all detected cores
    #TOTAL_CPU_COUNT=
    TOTAL_CPU_COUNT=112
    
    # Calculate the number of CPUs available for each NUMA node
    # Manually override the CPUs per node count
    #CPUS_PER_NODE=
    CPUS_PER_NODE=$((TOTAL_CPU_COUNT/NODE_COUNT))                # e.g, 56

    # Manually override the number of CPUs per group if you want set that manually
    #CPUS_PER_GROUP
    CPUS_PER_GROUP=$((CPUS_PER_NODE/GROUPS_PER_NODE_COUNT))      # e.g, 28
    
    # Hardcoded value depending on how you want to do scaling runs    
    # CPUS_PER_BACKEND=108  # Scale Run 0, e.g., pretend we are a composite run
    CPUS_PER_BACKEND=54     # Scale Run 1
    #CPUS_PER_BACKEND=26    # Scale Run 2
    #CPUS_PER_BACKEND=12    # Scale Run 3
    #CPUS_PER_BACKEND=5     # Scale Run 4

    CPUS_FOR_NON_BE=$((CPUS_PER_NODE-$((CPUS_PER_BACKEND*GROUPS_PER_NODE_COUNT))))
    OFFSET=$((CPUS_FOR_NON_BE/2))

    echo "TOTAL_CPU_COUNT is: $TOTAL_CPU_COUNT"
    echo "CPUS_PER_NODE is: $CPUS_PER_NODE"
    echo "CPUS_PER_GROUP is: $CPUS_PER_GROUP"
    echo "CPUS_PER_BACKEND is: $CPUS_PER_BACKEND"
    echo "CPUS_FOR_NON_BE is: $CPUS_FOR_NON_BE"
    echo "OFFSET is: $OFFSET"

    # We execute groups within the boundary of NUMA node (if no NUMA nodes are enabled then NODE_COUNT should == 1)
    for ((nodeNumber=0; nodeNumber<NODE_COUNT; nodeNumber=nodeNumber+1)) ; do

      echo -e "\nStarting Groups for NUMA Node $nodeNumber"

      local cpuInit=$((CPUS_PER_NODE*nodeNumber))                               # 56 * 0 = 0                56 * 1 = 56

      # Start the TransactionInjector JVMs and the Backend JVM for each group, the Controller 
      # will eventually connect and the benchmark will start
      for ((groupNumber=0; groupNumber<GROUPS_PER_NODE_COUNT; groupNumber=groupNumber+1)); do

        local groupId="Node${nodeNumber}Group${groupNumber}"
        echo -e "\nStarting Transaction Injector JVM(s) for node/group $groupId:"

        local becpuInit=0
        local becpuMax=0
        local cpuMax=0
        # We use some complicated arithmetic to create a CPU ranges             NODE 0 GROUP 0              NODE 1 GROUP 0
        if [ $groupNumber == 0 ] ; then
          cpuInit=$((cpuInit))                                                  # 0                         56         
        else
          cpuInit=$((cpuInit+CPUS_PER_BACKEND))
        fi
        becpuInit=$((cpuInit+OFFSET))                                           # 0 + 1 = 1                 56 + 1 = 57
        becpuMax=$((becpuInit+CPUS_PER_BACKEND-1))                              # 1 + 54 - 1 = 54           57 + 54 - 1 = 110
        
        local cpuRange="${becpuInit}-${becpuMax}"                               # 1-54                      57-110
        echo "cpuRange to be used for BE is: $cpuRange"

                                                                                # NODE 0 GROUP 0      NODE 0 GROUP 1      NODE 1 GROUP 0      NODE 1 GROUP 1
        #cpuInit=$((cpuInit))                                                   # 0                                       56
        #cpuInit=$((cpuInit+CPUS_PER_BACKEND))                                  #                     0 + 26 = 26                             56 + 26 = 82
        #becpuInit=$((cpuInit+OFFSET))                                          # 0 + 2 = 2           26 + 2 = 28         56 + 2 = 58         82 + 2 = 84
        #becpuMax=$((becpuInit+CPUS_PER_BACKEND-1))                             # 2 + 26 - 1 = 27     28 + 26 - 1 = 53    58 + 26 - 1 = 83    84 + 26 - 1 = 109
        #cpuRange="${becpuInit}-${becpuMax}"                                    # 2-27                28-53               58-83               84-109

                                                                                # NODE 0 GROUP 0      NODE 0 GROUP 1      NODE 0 GROUP 2      NODE 0 GROUP 3      NODE 1 GROUP 0      NODE 1 GROUP 1      NODE 1 GROUP 2      NODE 1 GROUP 3
        #cpuInit=$((cpuInit))                                                   # 0                                                                               56
        #cpuInit=$((cpuInit+CPUS_PER_BACKEND))                                  #                     0 + 12 = 12         12 + 12 = 24        24 + 12 = 36                            56 + 12 = 68        68 + 12 = 80        80 + 12 = 92
        #becpuInit=$((cpuInit+OFFSET))                                          # 0 + 4 = 4           12 + 4 = 16         24 + 4 = 28         36 + 4 = 40                             68 + 4 = 72         80 + 4 = 84         92 + 4 = 96
        #becpuMax=$((becpuInit+CPUS_PER_BACKEND-1))                             # 4 + 12 - 1 = 15     16 + 12 - 1 = 27    28 + 12 - 1 = 39    40 + 12 - 1 = 51    60 + 12 - 1 = 71    72 + 12 - 1 = 83    84 + 12 - 1 = 95    96 + 12 - 1 = 107    
        #cpuRange="${becpuInit}-${becpuMax}"                                    # 4-15                16-27               28-39               40-51               60-71               72-83               84-95               96-107

        for ((injectorNumber=1; injectorNumber<TI_JVM_COUNT+1; injectorNumber=injectorNumber+1)); do

            local transactionInjectorJvmId="txiJVM${injectorNumber}"
            local transactionInjectorName="$groupId.TxInjector.${transactionInjectorJvmId}"

            echo "Start $transactionInjectorName"

            # NOTE: We are deliberately not running TI's bound to a particular range, so we remove the prefix of numactl --physcpubind=$cpuRange --localalloc          
            # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
            # shellcheck disable=SC2086
            local transactionInjectorCommand="${JAVA} ${JAVA_OPTS_TI} ${SPECJBB_OPTS_TI} -jar ${SPECJBB_JAR} -m TXINJECTOR -G=$groupId -J=${transactionInjectorJvmId} ${MODE_ARGS_TI} > ${transactionInjectorName}.log 2>&1 &"
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

        echo "Start $backendName"
        # We don't double quote escape all arguments as some of those are being passed in as a list with spaces
        # shellcheck disable=SC2086
        local backendCommand="numactl --physcpubind=$cpuRange --localalloc ${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m BACKEND -G=$groupId -J=$backendJvmId ${MODE_ARGS_BE} > ${backendName}.log 2>&1 &"
        # NOTE: If you are not running in NUMA mode then remove the numactl --physcpubind=$cpuRange --localalloc prefix
        #local backendCommand="${JAVA} ${JAVA_OPTS_BE_WITH_GC_LOG} ${SPECJBB_OPTS_BE} -jar ${SPECJBB_JAR} -m BACKEND -G=$groupId -J=$backendJvmId ${MODE_ARGS_BE} > ${backendName}.log 2>&1 &"
        echo "$backendCommand"
        eval "${backendCommand}"
        echo -e "\t$backendName PID = $!"

        # Sleep for 1 second to allow each backend JVM to start.
        # TODO this seems arbitrary, we should detect the actual start of the BE
        sleep 1
      done
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
    cpuCount=$((cpuCount+1))
    
    echo
    echo "SPECjbb2015 is running..."
    echo "Please monitor $result/composite.out for progress"
    wait $compositePid

    echo "SPECjbb2015 has finished"
    echo
    
    cd "${WORKING_DIR}" || exit

  done
}

# NOTE: If the system does not have NUMA, then comment this out
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
