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
#jdk_bin_path="../jdks/$jdk/bin/"
jdk_bin_path="${TEST_JDK_HOME}/bin/"
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
writebarrier_benchmark_filter="WriteBarrier"
#crypto_benchmark_filter="(?i)crypto"

# Start the actual benchmark run
run_benchmarks $writebarrier_benchmark_filter
#run_benchmarks $crypto_benchmark_filter

# Display the date and time when the benchmarks complete
date