
<!--
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[1]https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
-->

# TechEmpower Framework Benchmarks (TFB)

The TechEmpower Framework Benchmarks is an [open source](https://github.com/TechEmpower/FrameworkBenchmarks) performance comparison of many web application frameworks executing tasks such as JSON serialization, database access, and server-side template composition. AQA performance testing currently only supports the [spring](https://github.com/TechEmpower/FrameworkBenchmarks/tree/master/frameworks/Java/spring) and [jetty](https://github.com/TechEmpower/FrameworkBenchmarks/tree/master/frameworks/Java/jetty) benchmarks, but other benchmarks may be added in the future.

## Running TechEmpower

Note that the current implementation in the AQA test framework assumes that Docker is installed on the test machine and the Docker daemon is running before TFB tests are run. 

The [TechEmpower wiki](https://github.com/TechEmpower/FrameworkBenchmarks/wiki/Development-Testing-and-Debugging) provides a list of options that can be passed to the tfb script to select certain tests (e.g. spring, jetty) and test types (e.g. json, db, fortune). 

The playlist.xml file currently includes the following options:   
tfb-spring-verify: runs `--mode verify --test spring`   
tfb-spring: runs `--test spring`   
tfb-jetty-verify: runs `--mode verify --test jetty`   
tfb-jetty: runs `--test jetty`
   
Additional arguments, such as to configure the test Docker container, can be passed through the `EXTRA_DOCKER_ARGS` environment variable.

`--test-container-memory` allows the user to specify the amount of memory given to the test Docker container, e.g., by specifying `--test-container-memory 1G`   

`--extra-docker-runtime-args` allows the user to pass in any additional Docker arguments as a space separated list of [arg name]:[arg value] pairs, e.g., by specifying `--extra-docker-runtime-args cpu_period:10000 cpu_quota:50000`

