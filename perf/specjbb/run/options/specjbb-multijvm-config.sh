#!/usr/bin/env bash

###################################################################################
#
# specjbb-multijvm-config.sh - 13th Of July 2023
# 
# NOTE for Microsoft Developers. This script was hastily extracted from the 
# aqa-test perf lab framework to be used standalone. Some of the logical flow may 
# come across as a little inverted due to this extraction process.
#
# Usage: This is a config script that is called by run_specjbb2015.sh
#
# TODO: A possible refactoring would be to allow most of these variables to be 
#       passed in by a calling framework.
# TODO: A alternative possible refactoring would be to not have individual
#       variables for all of these values and simply have a list of command line 
#       arguments that could be commented in/out.
# TODO: A possible refactoring would allow shared config with the composite mode
#  
###################################################################################

###################################################################################
# Groups and Looping Factors
#
# This section configures the looping of a SPECjbb run in multi-jvm mode
# e.g., 1 Controller is used to control X groups, of which each group consists of 
#       Y TransactionInjectors and 1 Backend
#
# When running on NUMA, a Groups should be sized/mapped inside a NUMA node.
#
# This section configures the looping of a SPECjbb run in multi-jvm mode
# e.g., 1 group consisting of 1 TransactionInjector and 1 Backend
# e.g., 2 groups consisting of 1 TransactionInjector and 1 Backend each
#
###################################################################################
export NUM_OF_RUNS=1
export NODE_COUNT=1                                         # Use this value (1) if not running on (pseudo) NUMA
#export NODE_COUNT=2                                        
# Number of groups
export GROUP_COUNT=1                                        # Scale Run 0, e.g., Match a composite run as closely as possible
#export GROUP_COUNT=2                                       # Scale Run 1
#export GROUP_COUNT=4                                       # Scale Run 2
#export GROUP_COUNT=8                                       # Scale Run 3
#export GROUP_COUNT=16                                      # Scale Run 4
export GROUPS_PER_NODE_COUNT=$((GROUP_COUNT/NODE_COUNT))    # Number of groups PER NUMA node
export TI_JVM_COUNT=2                                       # Number of TI's per group

###################################################################################
# SPECjbb config
#
# This section will configure the works, thread counts and saturation
# Please refer to the Java Engineering Group, Azure Compute and SPECjbb2015 user 
# guides and configuration spreadsheets for more details
#
# e.g., Configuration for a Maxed out (from a scaling perspective) Standard_D64s_v5 
# run as per the Java Engineering Group Azure VM SKU SPECjbb2015 guide
###################################################################################
#export TIER1=128                # number of cores x 2
#export TIER2=14                 # We hardcode this to 14 for Ampere Altra as per the Java Engineering Group Azure VM SKU SPECjbb2015 guide
#export TIER3=24                 # We hardcode this to 24 for Ampere Altra as per the Java Engineering Group Azure VM SKU SPECjbb2015 guide. Not always required to be set
#export THREADS_SATURATION=96    # We hardcode this to 96 for Ampere Altra as per the Java Engineering Group Azure VM SKU SPECjbb2015 guide. Not always required to be set
#export SELECTOR_RUNNER_COUNT=10 # We hardcode this to 10 for Ampere Altra as per the Java Engineering Group Azure VM SKU SPECjbb2015 guide

# export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=$TIER1 -Dspecjbb.forkjoin.workers.Tier2=$TIER2 -Dspecjbb.forkjoin.workers.Tier3=$TIER3 -Dspecjbb.customerDriver.threads.saturate=$THREADS_SATURATION -Dspecjbb.comm.connect.selector.runner.count=$SELECTOR_RUNNER_COUNT"
# 2, 4, 8, 16 Groups
export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=216 -Dspecjbb.forkjoin.workers.Tier2=14 -Dspecjbb.forkjoin.workers.Tier3=24 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"     # Scale Run 0, e.g., Match a composite run as closely as possible
#export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=108 -Dspecjbb.forkjoin.workers.Tier2=14 -Dspecjbb.forkjoin.workers.Tier3=24 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"    # Scale Run 1
#export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=52 -Dspecjbb.forkjoin.workers.Tier2=14 -Dspecjbb.forkjoin.workers.Tier3=24 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"     # Scale Run 2
#export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=24 -Dspecjbb.forkjoin.workers.Tier2=14 -Dspecjbb.forkjoin.workers.Tier3=24 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"     # Scale Run 3
#export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=10 -Dspecjbb.forkjoin.workers.Tier2=14 -Dspecjbb.forkjoin.workers.Tier3=24 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"     # Scale Run 4

#export SPECJBB_OPTS_TI=""
export SPECJBB_OPTS_BE=""

###################################################################################
# Java Process Configuration
#
# This section configures the memory and GC logging configuration for the TI, 
# Controller and Backend. Please refer to the Java Engineering Group, Azure Compute 
# and SPECjbb2015 user guides and configuration spreadsheets for more details
#
# TODO refactor so the values are passed in by variables or a calling framework
#
# TODO Alternative refactor is to not have individual variables for all of these 
# but to have a list of command line arguments that could be commented in/out.
#
###################################################################################

# The Controller, TransactionInjector, and Backend (aka System Under Test; SUT) are configured to meet the minimum 
# hardware requirements suggested by SPECjbb 
# (see the SPECjbb 2015 user guide, section 2.3 'Minimum hardware requirements', for more details)

export C_XMS=2G
export C_XMX=2G
export C_XMN=1536M
export C_PARALLEL_GC_THREADS=2
export C_CI_COMPILER_COUNT=2

# Controller and TI share the same configuration
export JAVA_OPTS_C="-Xms$C_XMS -Xmx$C_XMX -Xmn$C_XMN -XX:+UseParallelGC -XX:ParallelGCThreads=$C_PARALLEL_GC_THREADS -XX:CICompilerCount=$C_CI_COMPILER_COUNT"
export JAVA_OPTS_TI="${JAVA_OPTS_C}"

# Backend has a different configuration
#export BE_XMS=4G
#export BE_XMX=4G
#export BE_XMN=3G
#export BE_PARALLEL_GC_THREADS=4

# Default Configuration e.g., Written out in full: export JAVA_OPTS_BE="-Xms4g -Xmx4g -Xmn3g -XX:+UseParallelGC -XX:ParallelGCThreads=4 -XX:-UseAdaptiveSizePolicy" 
#export JAVA_OPTS_BE="-Xms256M -Xmx256M -Xmn188M -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:+AlwaysPreTouch -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"
#export JAVA_OPTS_BE="-Xms$BE_XMS -Xmx$BE_XMX -Xmn$BE_XMN -XX:+UseParallelGC -XX:ParallelGCThreads=$BE_PARALLEL_GC_THREADS -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"
# 2, 4, 8, 16 Groups

# MM Cedar Crest SKU - TODO double check the -xMx and -Xmn values
# export JAVA_OPTS_BE="-Xms672G -Xmx672G -Xmn650G -XX:+UseParallelGC -XX:ParallelGCThreads=108 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"  # Scale Run 0  e.g., Match a composite run as closely as possible
#export JAVA_OPTS_BE="-Xms336G -Xmx336G -Xmn320G -XX:+UseParallelGC -XX:ParallelGCThreads=54 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"    # Scale Run 1
#export JAVA_OPTS_BE="-Xms168G -Xmx168G -Xmn160G -XX:+UseParallelGC -XX:ParallelGCThreads=26 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"    # Scale Run 2
#export JAVA_OPTS_BE="-Xms84G -Xmx84G -Xmn80G -XX:+UseParallelGC -XX:ParallelGCThreads=12 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"       # Scale Run 3
#export JAVA_OPTS_BE="-Xms42G -Xmx42G -Xmn40G -XX:+UseParallelGC -XX:ParallelGCThreads=5 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"        # Scale Run 4

# LL Cedar Crest SKU
export JAVA_OPTS_BE="-Xms336G -Xmx336G -Xmn320G -XX:+UseParallelGC -XX:ParallelGCThreads=108 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"    # Scale Run 0  e.g., Match a composite run as closely as possible
#export JAVA_OPTS_BE="-Xms168G -Xmx168G -Xmn160G -XX:+UseParallelGC -XX:ParallelGCThreads=54 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"   # Scale Run 1
#export JAVA_OPTS_BE="-Xms84G -Xmx84G -Xmn80G -XX:+UseParallelGC -XX:ParallelGCThreads=26 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"      # Scale Run 2
#export JAVA_OPTS_BE="-Xms42G -Xmx42G -Xmn40G -XX:+UseParallelGC -XX:ParallelGCThreads=12 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"      # Scale Run 3
#export JAVA_OPTS_BE="-Xms21G -Xmx21G -Xmn20G -XX:+UseParallelGC -XX:ParallelGCThreads=5 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"       # Scale Run 4

###################################################################################
# Extra Controller Configuration
#
# Placeholder in case extra fine tuning is required.
#
###################################################################################
export MODE_ARGS_C=""
export MODE_ARGS_TI=""
export MODE_ARGS_BE=""
