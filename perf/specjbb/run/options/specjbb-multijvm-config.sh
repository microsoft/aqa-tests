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
# TODO: A possible refactoring would allow shared config with the composite mode
#  
###################################################################################

###################################################################################
# Looping Factors
#
# This section configures the looping of a SPECjbb run in multi-jvm mode
# e.g., 1 group consisting of 1 TransactionInjector and 1 Backend
#
###################################################################################
export GROUP_COUNT=1
export TI_JVM_COUNT=1 
export NUM_OF_RUNS=1

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
export TIER1=128
export TIER2=14
export TIER3=24
export THREADS_SATURATION=96
export SELECTOR_RUNNER_COUNT=10

export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.forkjoin.workers.Tier1=$TIER1 -Dspecjbb.forkjoin.workers.Tier2=$TIER2 -Dspecjbb.forkjoin.workers.Tier3=$TIER3 -Dspecjbb.customerDriver.threads.saturate=$THREADS_SATURATION -Dspecjbb.comm.connect.selector.runner.count=$SELECTOR_RUNNER_COUNT"
export SPECJBB_OPTS_TI=""
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
###################################################################################

# The Controller, TransactionInjector, and Backend (aka System Under Test; SUT) are configured to meet the minimum 
# hardware requirements suggested by SPECjbb 
# (see the SPECjbb 2015 user guide, section 2.3 'Minimum hardware requirements', for more details)
#
# This implies that a machine should have at least 8GB of memory and 8 CPU cores to run this test
export JAVA_OPTS_C="-Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:CICompilerCount=4"
export JAVA_OPTS_TI="${JAVA_OPTS_C}"

# Default configuration for BE
# export JAVA_OPTS_BE="-Xms4g -Xmx4g -Xmn3g -XX:+UseParallelGC -XX:ParallelGCThreads=4 -XX:-UseAdaptiveSizePolicy" # Default configuration

# Configuration for a Maxed out (from a scaling perspective) Standard_D64s_v5 run as per the Java Engineering Group Azure VM SKU SPECjbb2015 guide
export JAVA_OPTS_BE="-Xms192g -Xmx192g -Xmn173g -XX:+UseParallelGC -XX:ParallelGCThreads=64 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData"

###################################################################################
# Extra Controller Configuration
#
# Placeholder in case extra fine tuning is required.
#
###################################################################################
export MODE_ARGS_C=""
export MODE_ARGS_TI=""
export MODE_ARGS_BE=""
