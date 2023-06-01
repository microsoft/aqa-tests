#!/bin/bash

# This script is based on one of Monica Beckwith's scripts.
function help
{
    echo -e "\nUsage: $0 [GC HeapSizeGB WorkerThreads WarmupTimeSeconds WarmupIterations MeasurementIterations [JvmArgs]]\n"
    echo "Example: $0 Parallel 80 1 10 5 5"
    echo "Example: $0 g1       80 1 10 5 5 -XX:MaxGCPauseMillis=30 -XX:MaxNewSize=30g"
}
source run/testenv.mk
function validate_numeric_args
{   
    echo "Validating numeric arguments. "
    if [[ $2 =~ [^0-9] ]]; then
        echo "Error: invalid heap size $2"
        echo "Error: please specify a numeric value for the heap size."
        help
        exit 3
    fi

    if [[ $3 =~ [^0-9] ]]; then
        echo "Error: invalid thread count $3"
        echo "Error: please specify a numeric value for worker thread count."
        help
        exit 4
   else
        parthreads="-XX:ParallelGCThreads=$3"
   fi

    if [[ $4 =~ [^0-9] ]]; then
        echo "Error: invalid warmup time $4"
        echo "Error: please specify a numeric value for warmup time in seconds."
        help
        exit 5
    fi

    if [[ $5 =~ [^0-9] ]]; then
        echo "Error: invalid warmup iterations $5"
        echo "Error: please specify a numeric value for warmup iterations."
        help
        exit 6
    fi

    if [[ $6 =~ [^0-9] ]]; then
        echo "Error: invalid measurement iterations $6"
        echo "Error: please specify a numeric value for measurement iterations."
        help
        exit 7
    fi
}

if [ $# -lt 6 ]
then
    help
    exit 1
fi

# Expand the arguments into an array
args=("$@")
jvm_args=""

function compute_jvm_args
{
    local total_args=$#;
    local i=6;

    while [ $i -lt $total_args ]
    do
        jvm_args="$jvm_args ${args[i]}"
        i=$((i + 1))
    done
}

shopt -s nocasematch
case $1 in
    parallel)
        echo "Info: Parallel GC selected"
        gc="-XX:+UseParallelGC"
        ;;
    g1)
        echo "Info: Garbage First GC selected"
        gc="-XX:+UseG1GC"
        ;;
    *)
        echo "Error: the specified GC ($1) is not supported"
        help
        exit 2
        ;;
esac

validate_numeric_args ${args[@]}
compute_jvm_args ${args[@]}

# https://docs.oracle.com/en/java/javase/17/docs/specs/man/java.html#advanced-garbage-collection-options-for-java
#
# -XX:+AlwaysPreTouch
#    Requests the VM to touch every page on the Java heap after requesting it from the operating system and before
#    handing memory out to the application. By default, this option is disabled and all pages are committed as the
#    application uses the heap space.
#
# https://docs.oracle.com/en/java/javase/17/docs/specs/man/java.html#advanced-runtime-options-for-java
#
# -XX:+UseLargePages
#    Enables the use of large page memory. By default, this option is disabled and large page memory isn't used.
#    See https://docs.oracle.com/en/java/javase/17/docs/specs/man/java.html#large-pages
#
#std_jvm_opts="-XX:+AlwaysPreTouch -XX:+UseLargePages"
std_jvm_opts="-XX:+AlwaysPreTouch"


declare specified_gc=$1
declare specified_heap_size=$2
declare num_worker_threads=$3
declare warmup_time=$4
declare warmup_iterations=$5
declare measurement_iterations=$6

# Sets the minimum and initial size (in bytes) of the heap. This value must be a multiple of 1024 and greater
# than 1 MB. Append the letter k or K to indicate kilobytes, m or M to indicate megabytes, g or G to indicate gigabytes.
jvm_initial_heap_size_option="-Xms"

# Specifies the maximum size (in bytes) of the heap. This value must be a multiple of 1024 and greater than 2 MB.
# Append the letter k or K to indicate kilobytes, m or M to indicate megabytes, or g or G to indicate gigabytes.
# The default value is chosen at runtime based on system configuration. For server deployments, -Xms and -Xmx are
# often set to the same value.
jvm_max_heap_size_option="-Xmx"
heap_size_units="G"
jvm_heap_size_opts="$jvm_initial_heap_size_option$specified_heap_size$heap_size_units $jvm_max_heap_size_option$specified_heap_size$heap_size_units"

echo "Info: Selected heap size: $specified_heap_size GB"
echo "Info: JVM heap size args: $jvm_heap_size_opts"
echo ""

timestamp=`date +%Y-%m-%d_%H-%M-%S`

# Read the value of TEST_RESROOT from the XML file
TEST_RESROOT=$(xmllint --xpath "//variable[@name='TEST_RESROOT']/text()" playlist.xml)

# Set the value as an environment variable
export TEST_RESROOT

# Access the environment variable
echo "Value of TEST_RESROOT: $TEST_RESROOT"

gc_heap_timestamp_str="$specified_gc-${specified_heap_size}G-$timestamp"
output_dir="${TEST_RESROOT}/applogs"
echo "Info: Output log directory : $output_dir"
human_readable_output_file="${output_dir}/${gc_heap_timestamp_str}.txt"
machine_readable_output_file="${output_dir}/${gc_heap_timestamp_str}_machine.txt"

#benchmark_jar_path="jmh-jdk-microbenchmarks/micros-uber/target/micros-uberpackage-1.0-SNAPSHOT.jar"
benchmark_jar_path="${TEST_RESROOT}/jmh-jdk-microbenchmarks/micros-uber/target/micros-uberpackage-1.0-SNAPSHOT.jar"
echo "Info : Benchmark Jar path : $benchmark_jar_path "

#
# Set up the benchmark arguments.
# The documentation for the various flags is included here for convenience.
# To view the full help, run `java $benchmark_jar_path -h`
#

#  -f <int>                    How many times to fork a single benchmark. Use 0 to 
#                              disable forking altogether. Warning: disabling 
#                              forking may have detrimental impact on benchmark 
#                              and infrastructure reliability, you might want 
#                              to use different warmup mode instead. (default: 
#                              5)
fork_opt="-f 1"

#  -si <bool>                  Should JMH synchronize iterations? This would significantly 
#                              lower the noise in multithreaded tests, by making 
#                              sure the measured part happens only when all workers 
#                              are running. (default: true)
synchronize_iterations_opt="-si true"

#  -i <int>                    Number of measurement iterations to do. Measurement 
#                              iterations are counted towards the benchmark score. 
#                              (default: 1 for SingleShotTime, and 5 for all other 
#                              modes)
measurement_iterations_opt="-i $measurement_iterations"

#  -w <time>                   Minimum time to spend at each warmup iteration. Benchmarks
#                              may generally run longer than iteration duration.
#                              (default: 10 s)
warmup_time_opt="-w $warmup_time"

#  -wi <int>                   Number of warmup iterations to do. Warmup iterations 
#                              are not counted towards the benchmark score. (default: 
#                              0 for SingleShotTime, and 5 for all other modes)
warmup_iterations_opt="-wi $warmup_iterations"

#  -t <int>                    Number of worker threads to run with. 'max' means 
#                              the maximum number of hardware threads available 
#                              on the machine, figured out by JMH itself. (default: 
#                              1)
worker_threads_opt="-t $num_worker_threads"

#  -o <filename>               Redirect human-readable output to a given file.
human_readable_output_file_opt="-o $human_readable_output_file"

#  -rff <filename>             Write machine-readable results to a given file. 
#                              The file format is controlled by -rf option. Please 
#                              see the list of result formats for available formats. 
#                              (default: jmh-result.<result-format>)
machine_readable_output_file_opt="-rff $machine_readable_output_file"

#  -rf <type>                  Format type for machine-readable results. These 
#                              results are written to a separate file (see -rff). 
#                              See the list of available result formats with -lrf. 
#                              (default: CSV)
#
# Output from `java $benchmark_jar_path -lrf`:
#  Available formats: text, csv, scsv, json, latex
format_type_opt="-rf text"

benchmark="-jar $benchmark_jar_path"
benchmark="$benchmark $fork_opt $synchronize_iterations_opt $warmup_time_opt"
benchmark="$benchmark $measurement_iterations_opt $warmup_iterations_opt"
benchmark="$benchmark $worker_threads_opt $human_readable_output_file_opt"
benchmark="$benchmark $machine_readable_output_file_opt $format_type_opt"

#jdk="jdk-17.0.3+7"
jdk_bin_path="${TEST_JDK_HOME}/bin/"
echo "Info : JDK home is : $jdk_bin_path "

if [ ! -d "$jdk_bin_path" ]; then
    echo "Warning: Could not find JDK bin path: $jdk_bin_path"
    echo "Warning: Using the java binary automatically selected by the shell."
    jdk_bin_path=""
fi

run_benchmarks()
{
    date
    local benchmark_filter_regex=$1

    echo "**** $jvm_heap_size_opts $timestamp Benchmarks started for filter $benchmark_filter_regex ****"

    benchmark_command="${jdk_bin_path}java $jvm_heap_size_opts $parthreads $std_jvm_opts $jvm_args $benchmark \"$benchmark_filter_regex\""
    echo $benchmark_command
    eval $benchmark_command

    echo "**** $jvm_heap_size_opts $timestamp Benchmarks completed for filter $benchmark_filter_regex ****"
}

#atomics_benchmark_filter="(?i)\.*(atomic|lock|volatile|ConcurrentHashMap|ProducerConsumer|Queues|ThreadLocalRandomNextInt)\.*"
#atomics_benchmark_filter="(?i)\.*(atomiclongget|atomiclongnever|iallocationswithnullvolatile|recursivesynchronization|simplelock|callsitetarget)\.*"
#writebarrier_benchmark_filter="(?i)\.*(writebarrier)\.*"
writebarrier_benchmark_filter="WriteBarrier"

#crypto_benchmark_filter="(?i)crypto"

# Start the actual benchmark run.

run_benchmarks $writebarrier_benchmark_filter
#run_benchmarks $crypto_benchmark_filter

# Display the date and time when the benchmarks complete
date