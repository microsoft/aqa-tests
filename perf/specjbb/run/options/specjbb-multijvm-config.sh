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
export NODE_COUNT=2                                         # Set to 1 if not running on NUMA
export GROUP_COUNT=4                                        # Number of groups
export GROUPS_PER_NODE_COUNT=$((GROUP_COUNT/NODE_COUNT))    # Number of groups PER NUMA node
export TI_JVM_COUNT=1                                       # Number of TI's per group

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
export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=112 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"

#export SPECJBB_OPTS_C="-Dspecjbb.group.count=2 -Dspecjbb.txi.pergroup.count=1 -Dspecjbb.forkjoin.workers.Tier1=112 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"
#export SPECJBB_OPTS_C="-Dspecjbb.group.count=4 -Dspecjbb.txi.pergroup.count=1 -Dspecjbb.forkjoin.workers.Tier1=56 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"
#export SPECJBB_OPTS_C="-Dspecjbb.group.count=8 -Dspecjbb.txi.pergroup.count=1 -Dspecjbb.forkjoin.workers.Tier1=28 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"
#export SPECJBB_OPTS_C="-Dspecjbb.group.count=16 -Dspecjbb.txi.pergroup.count=1 -Dspecjbb.forkjoin.workers.Tier1=14 -Dspecjbb.customerDriver.threads.saturate=96 -Dspecjbb.comm.connect.selector.runner.count=10"
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

export C_XMS=2g
export C_XMX=2g
export C_XMN=1536m
export C_PARALLEL_GC_THREADS=2
export C_CI_COMPILER_COUNT=2

# Controller and TI share the same configuration
export JAVA_OPTS_C="-Xms$C_XMS -Xmx$C_XMX -Xmn$C_XMN -XX:+UseParallelGC -XX:ParallelGCThreads=$C_PARALLEL_GC_THREADS -XX:CICompilerCount=$C_CI_COMPILER_COUNT"
export JAVA_OPTS_TI="${JAVA_OPTS_C}"

# Backend has a different configuration
#export BE_XMS=4g
#export BE_XMX=4g
#export BE_XMN=3g
#export BE_PARALLEL_GC_THREADS=4   # 52

# Default Configuration e.g., Written out in full: export JAVA_OPTS_BE="-Xms4g -Xmx4g -Xmn3g -XX:+UseParallelGC -XX:ParallelGCThreads=4 -XX:-UseAdaptiveSizePolicy" 
#export JAVA_OPTS_BE="-Xms$BE_XMS -Xmx$BE_XMX -Xmn$BE_XMN -XX:+UseParallelGC -XX:ParallelGCThreads=$BE_PARALLEL_GC_THREADS -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"
# 2, 4, 8, 16 Groups
# 384GB -4G (Controller) -8G (Tx Injectors) -4G (OS) = 368G (Backends) --> 368G / 2 = 184G (per backend)
export JAVA_OPTS_BE="-Xms256M -Xmx256M -Xmn188M -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:+AlwaysPreTouch -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"
#export JAVA_OPTS_BE="-Xms184G -Xmx184G -Xmn165G -XX:+UseParallelGC -XX:ParallelGCThreads=52 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"

#export JAVA_OPTS_BE="-Xms92G -Xmx92G -Xmn82G -XX:+UseParallelGC -XX:ParallelGCThreads=25 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"
#export JAVA_OPTS_BE="-Xms46G -Xmx46G -Xmn41G -XX:+UseParallelGC -XX:ParallelGCThreads=12 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"
#export JAVA_OPTS_BE="-Xms23G -Xmx23G -Xmn20G -XX:+UseParallelGC -XX:ParallelGCThreads=6 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"
#export JAVA_OPTS_BE="-Xms12G -Xmx12G -Xmn10G -XX:+UseParallelGC -XX:ParallelGCThreads=3 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"

###################################################################################
# Extra Controller Configuration
#
# Placeholder in case extra fine tuning is required.
#
###################################################################################
export MODE_ARGS_C=""
export MODE_ARGS_TI=""
export MODE_ARGS_BE=""
