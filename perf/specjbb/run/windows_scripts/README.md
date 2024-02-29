# SPECjbb2015 Automation Scripts Guide

## Overview

This guide encompasses information on the use of automation scripts designed for the SPECjbb2015 benchmark, facilitating both Composite and MultiJVM modes. The scripts aim to simplify the execution process, enabling users to run the benchmark with customized settings through external configuration files.

## Available Scripts

1. Composite Mode Script (`run_composite.bat`): Automates the benchmark execution in Composite mode, where the Controller, TxInjector, and Backend are launched within a single JVM.

2. MultiJVM Mode Script (`run_multijvm.bat`): Facilitates running the Controller, TxInjectors, and Backends in separate JVMs on the same server, ideal for testing distributed setups or when isolating components is required.

## Features

- **Modular Configuration**: Both scripts read from separate `.config` files, allowing easy modification of parameters such as JVM options and benchmark settings without editing the scripts directly.
  
- **Result Organization**: Each execution generates a new directory named with a timestamp, containing all relevant logs and output files to ensure easy comparison between runs.
  
- **Customizable Execution**: Users can specify the number of runs and adjust settings for group counts, JVM counts per group, and more, depending on the script in use.

## Configuration Files

Each script uses a distinct configuration file (`specjbb2015config_composite.config` for Composite mode and `specjbb2015config_multijvm.config` for MultiJVM mode), which includes key-value pairs for setting benchmark parameters. These might include:

- JVM options (`JAVA_OPTS`)
- Benchmark options (`SPEC_OPTS`)
- Number of groups and TxInjector JVMs (MultiJVM mode)
- Execution-specific parameters like number of runs (`NUM_OF_RUNS`)

## Execution Instructions

To execute a benchmark:

1. Ensure `specjbb2015.jar`, the chosen script, and its corresponding configuration file are in the same directory.
2. Open a command prompt or terminal in the directory.
3. Run the script by typing its name and pressing Enter.

## Results

The scripts store the output in uniquely named directories for each run, including logs and benchmark results. This structured approach facilitates easy analysis and comparison of different executions.

## Extensibility

The documentation and scripts are designed with extensibility in mind. Additional scripts catering to new modes or specialized benchmarking scenarios can be easily integrated and described within this README framework.

## Troubleshooting

- **Java Executable Not Found**: Ensure the JAVA_PATH in the configuration file correctly points to your Java installation. Alternatively, verify Java's path is included in the system's PATH environment variable.
- **Memory Allocation Errors**: Review the JAVA_OPTS settings within the configuration file. Adjust them according to your system's memory availability and the benchmark's requirements.

For additional assistance, refer to the SPECjbb2015 [documentation](https://spec.org/jbb2015/) and ensure your Java installation meets the benchmark's prerequisites.
