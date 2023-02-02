#!/usr/bin/env bash
# This will configure a basic run of SPECjbb in multi-jvm mode
# Therefore, the topography of the run includes 1 group consisting of
# 1 TransactionInjector and 1 Backend

export GROUP_COUNT=1
export TI_JVM_COUNT=1 
export NUM_OF_RUNS=1

export SPECJBB_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT"
export SPECJBB_OPTS_TI=""
export SPECJBB_OPTS_BE=""

export JAVA_OPTS_C="-Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:CICompilerCount=4"
export JAVA_OPTS_TI="${JAVA_OPTS_C}" 
export JAVA_OPTS_BE="-Xms4g -Xmx4g -Xmn3g -XX:+UseParallelGC -XX:ParallelGCThreads=4 -XX:-UseAdaptiveSizePolicy"

export MODE_ARGS_C=""
export MODE_ARGS_TI=""
export MODE_ARGS_BE=""

