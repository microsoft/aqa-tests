#!/usr/bin/env bash

JMH_BUILD=$(JVM_TEST_ROOT)/perf/jmh

export APP_LOGS_PATH=$(JMH_BUILD)/applogs
export JMH_JAR_PATH=$(JMH_BUILD)/jmh-jdk-microbenchmarks/micros-uber/target/micros-uberpackage-1.0-SNAPSHOT.jar