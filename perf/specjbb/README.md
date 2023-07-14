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

# SPECjbb2015

SPECjbb2015 is a Java Client/Server performance testing benchmark.
Please visit its product page for more information, including a user guide: [https://www.spec.org/jbb2015/](https://www.spec.org/jbb2015/).

## Prerequisites

Since SPECjbb requires a license to run, this aqa-test config requires that a licensed copy of the benchmark already exists on the machine that you are running on.

## Run

13th Of July 2023

NOTE for Microsoft Developers. This script was hastily extracted from the
aqa-test perf lab framework to be used standalone. Some of the logical flow may
come across as a little inverted due to this extraction process.

Usage:

1. Set the environment variables at the top of the [run_specjbb2015.sh](./run/run_specjbb2015.sh) script.
2. Set the environment variables in the [run_specjbb-composite-config.sh](./run/options/specjbb-composite-config.sh) or
    [run_specjbb-multijvm-config.sh](./run/options/specjbb-multijvm-config.sh) script depending on the mode you want to
    run in
3. [run_specjbb2015.sh](./run/run_specjbb2015.sh) - will run the benchmark and generate a report
